TEMPLATE = aux

TS_FILE = $$PWD/mitakuuluu2.ts

ts.commands += lupdate $$PWD/.. -ts $$TS_FILE
ts.CONFIG += no_check_exist no_link
ts.output = $$TS_FILE
ts.input = ..

#make transifex site happy. sigh...
transifex.commands += sed -i -e \"s@<numerusform></numerusform>@<numerusform></numerusform>\\n            <numerusform></numerusform>@\" $$TS_FILE
transifex.CONFIG += no_check_exist no_link
transifex.output = $$TS_FILE
transifex.input = ..

QMAKE_EXTRA_TARGETS += ts transifex
PRE_TARGETDEPS += ts transifex

TRANSLATIONS += \
    ca.ts \
    crh.ts \
    cs.ts \
    da_DK.ts \
    de.ts \
    de_CH.ts \
    de_DE.ts \
    el.ts \
    en_US.ts \
    es.ts \
    fi.ts \
    fr_FR.ts \
    gl.ts \
    it_IT.ts \
    ml_IN.ts \
    nl.ts \
    nl_BE.ts \
    pl.ts \
    pt_BR.ts \
    ru_RU.ts \
    si_LK.ts \
    sl_SI.ts \
    sv_SE.ts \
    sq_AL.ts \
    tr_TR.ts \
    zh_CN.ts \
    zh_HK.ts \
    zh.ts \
    $${NULL}

build_translations.target = build_translations
build_translations.commands += lrelease \"$${_PRO_FILE_}\"

QMAKE_EXTRA_TARGETS += build_translations
POST_TARGETDEPS += build_translations

qm.files = $$replace(TRANSLATIONS, .ts, .qm)
qm.path = /usr/share/harbour-mitakuuluu2/locales
qm.CONFIG += no_check_exist

INSTALLS += qm

OTHER_FILES += $$TRANSLATIONS

