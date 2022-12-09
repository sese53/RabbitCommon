#ifndef CDOWNLOADFILE_H
#define CDOWNLOADFILE_H

#include <QUrl>
#include <QFile>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QLoggingCategory>

#include "rabbitcommon_export.h"

namespace RabbitCommon {

/*!
 * \~chinese 从多个 URLS 下载同一个文件
 * 
 * \~english
 * \brief Download the same file from multiple URLs
 */
class RABBITCOMMON_EXPORT CDownloadFile : public QObject
{
    Q_OBJECT

public:
    /*!
     * \chinese
     * \param urls:
     * \param bSequence:
     *     TRUE: 按顺序向 urls 发起请求。前一个请求失败后，才请示后一个。如果成功，则返回。
     *     FALSE: 同时向所有 urls 发起请求。
     * \param parent
     *
     * \english
     * \param urls:
     * \param bSequence: Whether the requests are made in order.
     *                   After the previous request fails,
     *                   the latter one is requested.
     *                   Returns if successful
     * \param parent
     */
    explicit CDownloadFile(QVector<QUrl> urls,
                           bool bSequence = false,
                           QObject *parent = nullptr);
    virtual ~CDownloadFile();

signals:
    void sigFinished(const QString szFile);
    void sigError(int nErr, const QString szErr);
    void sigDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);

private:
    /**
     * @brief DownloadFile
     * @param nIndex: url index
     * @param url: Download url
     * @param bRedirection: true: Is redirection
     * @return 
     */
    int DownloadFile(int nIndex, const QUrl &url, bool bRedirection = false);

private Q_SLOTS:
    void slotReadyRead();
    void slotError(QNetworkReply::NetworkError e);
    void slotSslError(const QList<QSslError> e);
    void slotDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void slotFinished();

private:
    QLoggingCategory m_Log;
    bool m_bSequence;
    QVector<QUrl> m_Url;
    QVector<QSharedPointer<QFile> > m_DownloadFile;
    bool m_bDownload;
    QNetworkAccessManager m_NetManager;
    QMap<QNetworkReply*, int> m_Reply;
    qint64 m_nBytesReceived;
    QString m_szError;
};

} // namespace RabbitCommon

#endif // CDOWNLOADFILE_H
