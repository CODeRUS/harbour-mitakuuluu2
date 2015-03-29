#ifndef THREADWORKER_H
#define THREADWORKER_H

#include <QObject>
#include <QVariant>
#include <QRunnable>
#include <QThreadPool>

class ThreadWorker;
class WorkerTask: public QRunnable
{
public:
    WorkerTask(ThreadWorker *worker,
               QVariant payload){
        m_worker = worker;
        m_payload = payload;
    }
    ThreadWorker *m_worker;
    QVariant m_payload;

    void run();
};

class ThreadWorker: public QObject
{
    Q_OBJECT
    friend class WorkerTask;
public:
    explicit ThreadWorker(QObject *parent = 0);
    void setCallObject(QObject *object);

public slots:
    void queueAction(QVariant msg, int priority = 0);

protected:
    void processAction(QVariant msg);

private:
    QThreadPool m_pool;
    QObject * m_object;
};

#endif // THREADWORKER_H
