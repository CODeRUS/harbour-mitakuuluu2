#include <QDebug>
#include <QObject>
#include <QVariant>
#include <QThreadPool>

#include "threadworker.h"

void WorkerTask::run() {
       m_worker->processAction(m_payload);
}

ThreadWorker::ThreadWorker(QObject * parent):
    QObject(parent) {
    m_pool.setMaxThreadCount(1);
    m_object = NULL;
}

void ThreadWorker::setCallObject(QObject *object) {
    m_object = object;
}

void ThreadWorker::queueAction(QVariant msg, int priority) {
    m_pool.start(new WorkerTask(this,msg), priority);
}

void ThreadWorker::processAction(QVariant msg) {
    if (m_object!=NULL) {
        QMetaObject::invokeMethod(m_object, "processAction", Qt::DirectConnection,
                Q_ARG(QVariant, msg));
    } else {
        qDebug() << "Target reciever not set";
    }
}
