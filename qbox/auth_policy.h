/*
 ============================================================================
 Name        : auth_policy.h
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#ifndef QBOX_AUTH_POLICY_H
#define QBOX_AUTH_POLICY_H

/*============================================================================*/
/* type QBox_AuthPolicy */

typedef struct _QBox_AuthPolicy {
	const char* scope;
	const char* callbackUrl;
	const char* returnUrl;
	int expires;
} QBox_AuthPolicy;

char* QBox_MakeUpToken(const QBox_AuthPolicy* auth);

/*============================================================================*/

#endif /* QBOX_AUTH_POLICY_H */

