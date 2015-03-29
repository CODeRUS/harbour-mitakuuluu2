#ifndef AUDIORECORDER_H
#define AUDIORECORDER_H

#include <QObject>
#include <QAudioRecorder>
#include <QAudioEncoderSettings>
#include <QMultimedia>

typedef QMultimedia::AvailabilityStatus AvailabilityStatus;

class AudioRecorder : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QMediaRecorder::Status status READ getStatus NOTIFY statusChanged)
    Q_PROPERTY(QMediaRecorder::State state READ getState NOTIFY stateChanged)
    Q_PROPERTY(qint64 duration READ getDuration NOTIFY durationChanged)
    Q_PROPERTY(QMediaRecorder::Error error READ getLastError NOTIFY errorOccured)
    Q_PROPERTY(QMultimedia::AvailabilityStatus availability READ getAvailability NOTIFY availabilityChanged)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)

    Q_ENUMS(QMediaRecorder::Status)
    Q_ENUMS(QMediaRecorder::State)
    Q_ENUMS(QMediaRecorder::Error)
    Q_ENUMS(AvailabilityStatus)

public:
    explicit AudioRecorder(QObject *parent = 0);
    virtual ~AudioRecorder();

private:
    QString getTempPath();

    QString path();
    void setPath(const QString &path);

    QMediaRecorder::Status getStatus();
    QMediaRecorder::State getState();
    qint64 getDuration();
    QMediaRecorder::Error getLastError();
    QMultimedia::AvailabilityStatus getAvailability();

    QAudioRecorder *_rec;

    QMediaRecorder::Status _status;
    QMediaRecorder::State _state;
    qint64 _duration;
    QMediaRecorder::Error _lastError;
    QMultimedia::AvailabilityStatus _availability;

private slots:
    void onStatusChanged(QMediaRecorder::Status status);
    void onStateChanged(QMediaRecorder::State state);
    void onDurationChanged(qint64 duration);
    void onError(QMediaRecorder::Error error);
    void onAvailabilityChanged(QMultimedia::AvailabilityStatus availability);

signals:
    void statusChanged();
    void stateChanged();
    void durationChanged();
    void errorOccured();
    void availabilityChanged();
    void pathChanged();

public slots:
    Q_INVOKABLE void record();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void pause();
};

#endif // AUDIORECORDER_H
