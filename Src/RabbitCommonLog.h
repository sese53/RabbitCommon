/** @copyright Copyright (c) Kang Lin studio, All Rights Reserved
 *  @author Kang Lin(kl222@126.com)
 *  @abstract log
 */

#ifndef RABBIT_COMMON_LOG_H
#define RABBIT_COMMON_LOG_H

#pragma once

#include <QObject>
#include <QDataStream>
#include "rabbitcommon_export.h"

namespace RabbitCommon {

#define LM_DEBUG 0
#define LM_INFO 1
#define LM_WARNING 2
#define LM_ERROR 3

#ifdef DEBUG
    #define LOG_MODEL_DEBUG(model, ...)
#else
    #define LOG_MODEL_DEBUG(model, ...) RabbitCommon::CLog::Instance()->Print(__FILE__, __LINE__, Q_FUNC_INFO, LM_DEBUG, model, __VA_ARGS__)
#endif //#ifdef DEBUG

#define LOG_MODEL_ERROR(model, ...) RabbitCommon::CLog::Instance()->Print(__FILE__, __LINE__, Q_FUNC_INFO, LM_ERROR, model, __VA_ARGS__)
#define LOG_MODEL_WARNING(model, ...) RabbitCommon::CLog::Instance()->Print(__FILE__, __LINE__, Q_FUNC_INFO, LM_WARNING, model, __VA_ARGS__)
#define LOG_MODEL_INFO(model, ...) RabbitCommon::CLog::Instance()->Print(__FILE__, __LINE__, Q_FUNC_INFO, LM_INFO, model, __VA_ARGS__)

//DON'T USE CLog!!!
class RABBITCOMMON_EXPORT CLog
{
public:
    CLog();

    static CLog* Instance();
    int EnablePrintThread(bool bPrint);
    
    /**
     * @brief 日志输出
     * @param pszFile:打印日志处文件名
     * @param nLine:打印日志处行号
     * @param nLevel:打印日志错误级别
     * @param pszModelName:打印日志的模块范围
     * @param pFormatString:格式化字符串
     * @return 
     */
    int Print(const char *pszFile, int nLine, const char* pszFunction, int nLevel,
            const char* pszModelName, const char *pFormatString, ...);
    
private:
    bool m_bEnablePrintThread;
};

} // End namespace RabbitCommon

#endif // RABBIT_COMMON_LOG_H
