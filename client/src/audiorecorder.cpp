#include "audiorecorder.h"

#include <QDir>
#include <QFile>
#include <QDateTime>
#include <QUrl>
#include <QStandardPaths>

AudioRecorder::AudioRecorder(QObject *parent) :
    QObject(parent)
{
    QDir::home().mkpath(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    _rec = new QAudioRecorder(this);
    QAudioEncoderSettings settings;
    settings.setCodec("audio/vorbis");
    settings.setQuality(QMultimedia::NormalQuality);
    settings.setEncodingMode(QMultimedia::ConstantQualityEncoding);

    _rec->setEncodingSettings(settings, QVideoEncoderSettings(), "ogg");

    _status = _rec->status();
    _state = _rec->state();
    _duration = _rec->duration();
    _lastError = _rec->error();
    _availability = _rec->availability();

    QObject::connect(_rec, SIGNAL(statusChanged(QMediaRecorder::Status)), this, SLOT(onStatusChanged(QMediaRecorder::Status)));
    QObject::connect(_rec, SIGNAL(stateChanged(QMediaRecorder::State)), this, SLOT(onStateChanged(QMediaRecorder::State)));
    QObject::connect(_rec, SIGNAL(durationChanged(qint64)), this, SLOT(onDurationChanged(qint64)));
    QObject::connect(_rec, SIGNAL(error(QMediaRecorder::Error)), this, SLOT(onError(QMediaRecorder::Error)));
    QObject::connect(_rec, SIGNAL(availabilityChanged(QMultimedia::AvailabilityStatus)), this, SLOT(onAvailabilityChanged(QMultimedia::AvailabilityStatus)));
}

AudioRecorder::~AudioRecorder()
{
    delete _rec;
}

QString AudioRecorder::getTempPath()
{
    return QString("%1/%2.%3").arg(QStandardPaths::writableLocation(QStandardPaths::CacheLocation))
                              .arg(QDateTime::currentDateTime().toString("dd_MM_yyyy-hh_mm_ss"))
                              .arg(_rec->containerFormat());
}

QString AudioRecorder::path()
{
    return _rec->outputLocation().toString();
    emit pathChanged();
}

void AudioRecorder::setPath(const QString &path)
{
    if (_rec->state() == QMediaRecorder::StoppedState)
        _rec->setOutputLocation(QUrl(path));
}

QMediaRecorder::Status AudioRecorder::getStatus()
{
    return _status;
}

QMediaRecorder::State AudioRecorder::getState()
{
    return _state;
}

qint64 AudioRecorder::getDuration()
{
    return _duration;
}

QMediaRecorder::Error AudioRecorder::getLastError()
{
    return _lastError;
}

QMultimedia::AvailabilityStatus AudioRecorder::getAvailability()
{
    return _availability;
}

void AudioRecorder::onStatusChanged(QMediaRecorder::Status status)
{
    _status = status;
    emit statusChanged();
}

void AudioRecorder::onStateChanged(QMediaRecorder::State state)
{
    _state = state;
    emit stateChanged();
}

void AudioRecorder::onDurationChanged(qint64 duration)
{
    _duration = duration;
    emit durationChanged();
}

void AudioRecorder::onError(QMediaRecorder::Error error)
{
    _lastError = error;
    emit errorOccured();
}

void AudioRecorder::onAvailabilityChanged(QMultimedia::AvailabilityStatus availability)
{
    _availability = availability;
    emit availabilityChanged();
}

void AudioRecorder::record()
{
    /*if (path.isEmpty())
        _rec->setOutputLocation(QUrl(getTempPath()));
    else
        _rec->setOutputLocation(QUrl(path));
    emit pathChanged();*/
    if (_rec->state() == QMediaRecorder::StoppedState)
        _rec->setOutputLocation(QUrl(getTempPath()));
    _rec->record();
}

void AudioRecorder::stop()
{
    _rec->stop();
}

void AudioRecorder::pause()
{
    _rec->pause();
}
