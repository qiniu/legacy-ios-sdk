/*
 ============================================================================
 Name        : base_io.c
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#import <Foundation/Foundation.h>
#include "base.h"
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#ifndef O_BINARY
#define O_BINARY	0
#endif

/*============================================================================*/
/* QBox_Section_Reader */

typedef struct _QBox_sectionReader {
	QBox_ReaderAt r;
	off_t off;
	off_t limit;
} QBox_sectionReader;

static size_t QBox_sectionReader_Read(void *buf, size_t unused, size_t n, void *self1)
{
	QBox_sectionReader* self = (QBox_sectionReader*)self1;
	off_t max = self->limit - self->off;
	if (max <= 0) {
		return 0;
	}
	if (n > max) {
		n = (size_t)max;
	}
	n = self->r.ReadAt(self->r.self, buf, n, self->off);
	if (n < 0) {
		n = 0;
	}
	self->off += n;
	return n;
}

QBox_Reader QBox_SectionReader(QBox_ReaderAt r, off_t off, off_t n)
{
	QBox_Reader ret;
	QBox_sectionReader* self = malloc(sizeof(QBox_sectionReader));
	self->r = r;
	self->off = off;
	self->limit = off + n;
	ret.self = self;
	ret.Read = QBox_sectionReader_Read;
	return ret;
}

void QBox_SectionReader_Release(void* f)
{
	free(f);
}

/*============================================================================*/
/* QBox_File_ReaderAt */

static ssize_t QBox_file_ReadAt(void* self, void *buf, size_t count, off_t offset)
{
	return pread((int)self, buf, count, offset);
}

QBox_ReaderAt QBox_FileReaderAt_Open(const char* file)
{
	QBox_ReaderAt ret;
	int fd = open(file, O_BINARY | O_RDONLY, 0644);
	if (fd != -1) {
		ret.self = (void*)fd;
		ret.ReadAt = QBox_file_ReadAt;
		return ret;
	}
	ret.self = NULL;
	return ret;
}

void QBox_FileReaderAt_Close(void* self)
{
	close((int)self);
}

/*============================================================================*/

