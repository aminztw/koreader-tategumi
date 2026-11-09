describe("ReaderTypeset vertical reading", function()
    local ReaderTypeset

    setup(function()
        require("commonrequire")
        ReaderTypeset = require("apps/reader/modules/readertypeset")
    end)

    local function new_typeset(tweak_css)
        return setmetatable({
            ui = {
                styletweak = {
                    getCssText = function() return tweak_css end,
                },
            },
            genStyleSheetMenu = function() return {} end,
        }, { __index = ReaderTypeset })
    end

    it("appends vertical layout CSS without discarding style tweaks", function()
        local typeset = new_typeset("p { text-align: justify; }")
        typeset.vertical_reading = true

        local css = typeset:getAppendedStyleSheet()

        assert.is_truthy(css:find("p { text%-align: justify; }"))
        assert.is_truthy(css:find("writing%-mode: vertical%-rl !important;"))
        assert.is_truthy(css:find("text%-orientation: mixed !important;"))
    end)

    it("leaves style tweaks unchanged when vertical reading is disabled", function()
        local typeset = new_typeset("body { font-family: serif; }")
        typeset.vertical_reading = false

        assert.are.equal("body { font-family: serif; }", typeset:getAppendedStyleSheet())
    end)

    it("adds the toggle under Document settings", function()
        local typeset = new_typeset("")
        local menu_items = {
            document_settings = { sub_item_table = {} },
        }

        typeset:addToMainMenu(menu_items)

        assert.are.equal(1, #menu_items.document_settings.sub_item_table)
        assert.are.equal("Vertical reading", menu_items.document_settings.sub_item_table[1].text)
        assert.is_truthy(menu_items.document_settings.sub_item_table[1].help_text:find("horizontal reading", 1, true))
    end)

    it("applies vertical CSS in place and warns only when enabling", function()
        local UIManager = require("ui/uimanager")
        local original_show = UIManager.show
        local shown_message
        local applied_stylesheet
        local update_event
        local set_view_mode_event
        local saved_setting
        local typeset = setmetatable({
            vertical_reading = false,
            ui = {
                doc_settings = {
                    saveSetting = function(_, key, value)
                        saved_setting = { key, value }
                    end,
                    isTrue = function() return false end,
                    has = function() return false end,
                },
                document = {
                    setStyleSheet = function(_, css, tweaks_css)
                        applied_stylesheet = { css, tweaks_css }
                    end,
                    hasVerticalContent = function() return false end,
                },
                view = {
                    view_mode = "scroll",
                    syncProgressBarDirection = function() end,
                    refreshPageTurnInput = function() end,
                },
                handleEvent = function(_, event)
                    if event.handler == "onUpdatePos" then
                        update_event = event
                    elseif event.handler == "onSetViewMode" then
                        set_view_mode_event = event
                    end
                end,
                rolling = {},
                reloadDocument = function()
                    error("vertical toggle should not reload the document")
                end,
                styletweak = {
                    getCssText = function() return "p { text-align: justify; }" end,
                },
            },
        }, { __index = ReaderTypeset })

        UIManager.show = function(_, message) shown_message = message end
        local ok, err = pcall(function()
            assert.is_true(typeset:onToggleVerticalReading(true))
            assert.are.same({ "vertical_reading", true }, saved_setting)
            assert.are.equal(typeset.css, applied_stylesheet[1])
            assert.is_truthy(applied_stylesheet[2]:find("writing%-mode: vertical%-rl !important;"))
            assert.are.equal("onUpdatePos", update_event.handler)
            assert.are.equal("onSetViewMode", set_view_mode_event.handler)
            assert.are.equal("page", set_view_mode_event.args[1])
            assert.is_true(typeset.ui.view.inverse_reading_order_forced)
            assert.are.equal(not require("ui/bidi").mirroredUILayout(),
                typeset.ui.view.inverse_reading_order)
            assert.is_truthy(shown_message.text:find("horizontal reading", 1, true))
            assert.are.equal(5, shown_message.timeout)
            assert.are.equal("notice-warning", shown_message.icon)

            shown_message = nil
            assert.is_true(typeset:onToggleVerticalReading(false))
            assert.are.same({ "vertical_reading", nil }, saved_setting)
            assert.is_nil(applied_stylesheet[2]:find("writing%-mode: vertical%-rl !important;"))
            assert.is_false(typeset.ui.view.inverse_reading_order_forced)
            assert.are.equal(G_reader_settings:isTrue("inverse_reading_order"),
                typeset.ui.view.inverse_reading_order)
            assert.is_nil(shown_message)
        end)
        UIManager.show = original_show
        assert.is_true(ok, err)
    end)

end)
