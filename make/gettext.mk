PHONY += mo mo-clean po pot

SELF := $(lastword $(MAKEFILE_LIST))

DOMAIN = koreader
TEMPLATE_DIR = l10n/templates
MSGFMT_BIN = msgfmt
XGETTEXT_BIN = xgettext

CUSTOM_ZH_TW_MO = l10n_custom/zh_TW/$(DOMAIN).mo
PO_FILES = $(filter-out l10n/zh_TW/$(DOMAIN).po,$(wildcard l10n/*/*.po))
MO_FILES = $(PO_FILES:%.po=%.mo)

%.mo: %.po
	@$(MSGFMT_BIN) --no-hash -o $@ $<

mo:
	install -d l10n/zh_TW
	install -m 644 $(CUSTOM_ZH_TW_MO) l10n/zh_TW/$(DOMAIN).mo
ifneq (,$(MO_FILES))
	$(MAKE) $(if $(PARALLEL_JOBS),--jobs=$(PARALLEL_JOBS)) $(if $(PARALLEL_LOAD),--load-average=$(PARALLEL_LOAD)) --silent --file=$(SELF) $(MO_FILES)
endif

mo-clean:
	rm -f l10n/zh_TW/$(DOMAIN).mo
ifneq (,$(MO_FILES))
	rm -f $(MO_FILES)
endif

pot: po
	mkdir -p $(TEMPLATE_DIR)
	$(XGETTEXT_BIN) --from-code=utf-8 \
		--keyword=C_:1c,2 --keyword=N_:1,2 --keyword=NC_:1c,2,3 \
		--add-comments=@translators \
		reader.lua `find frontend -iname "*.lua" | sort` \
		`find plugins -iname "*.lua" | sort` \
		`find tools -iname "*.lua" | sort` \
		-o $(TEMPLATE_DIR)/$(DOMAIN).pot

po:
	@true
