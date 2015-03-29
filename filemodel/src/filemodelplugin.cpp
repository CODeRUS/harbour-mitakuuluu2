#include "filemodelplugin.h"
#include "filemodel.h"
#include "filesortmodel.h"

#include <qqml.h>

void FilemodelPlugin::registerTypes(const char *uri)
{
    // @uri harbour.mitakuuluu2.filemodel
    qmlRegisterType<FileSourceModel>(uri, 1, 0, "FileSourceModel");
    qmlRegisterType<FileSortModel>(uri, 1, 0, "FileSortModel");
}
