TEMPLATE = subdirs
SUBDIRS = \
    locales \
    server \
    client \
    filemodel \
    shareui \
    sharecontacts \
    translator \
    androidhelper \
    $${NULL}

OTHER_FILES = \
    rpm/harbour-mitakuuluu2.spec
