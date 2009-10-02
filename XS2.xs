/*  -*- Mode: C -*- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include <sys/types.h>

/* malloc() */
#include <stdlib.h>

/* memset() */
#include <string.h>

#include <stdio.h>

#ifdef SOLARIS
typedef   uint32_t    u_int32_t;
#else
typedef   u_int32_t   in_addr_t;
#endif

u_int32_t bits[] = {
  0x80000000, 0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000,
  0x02000000, 0x01000000, 0x00800000, 0x00400000, 0x00200000, 0x00100000,
  0x00080000, 0x00040000, 0x00020000, 0x00010000, 0x00008000, 0x00004000,
  0x00002000, 0x00001000, 0x00000800, 0x00000400, 0x00000200, 0x00000100,
  0x00000080, 0x00000040, 0x00000020, 0x00000010, 0x00000008, 0x00000004,
  0x00000002, 0x00000001,
};

typedef struct _n {
  struct _n *zero;
  struct _n *one;
  char *code;
} Node;

#define MCB_MAX 1024
typedef struct {
  Node *block;
  int pos;
#define COUNT_MAX 1024*1024
} MCB;

typedef struct {
  Node *root;
  MCB *m_cb;
  int m_cur;
} XS2_CTX;

/* allocate mem block */
Node *alloc_m (XS2_CTX *ctx)
{
  Node *x;

  ctx->m_cur++;
  if (ctx->m_cur >= MCB_MAX) {
    /* memory exhausted */
    return NULL;
  }
  x = malloc(sizeof(Node) * COUNT_MAX);
  if (x != NULL) {
    memset(x, 0, sizeof(Node) * COUNT_MAX);
    ctx->m_cb[ctx->m_cur].block = x;
    ctx->m_cb[ctx->m_cur].pos = 0;
  }
  return x;
}

Node *alloc_1 (XS2_CTX *ctx)
{
  Node *x;
  if (ctx->m_cb[ctx->m_cur].pos >= COUNT_MAX-1) {
    x = alloc_m(ctx);
    if (x == NULL) {
      return x;
    }
  }
  return &(ctx->m_cb)[ctx->m_cur].block[ctx->m_cb[ctx->m_cur].pos++];
}

void free_m (pTHX_ XS2_CTX *ctx)
{
  int i;
  for (i=0; i< MCB_MAX; i++) {
    if (ctx->m_cb[i].block != NULL) {
      free(ctx->m_cb[i].block);
    }
  }
  free(ctx->m_cb);
}

int init (pTHX_ XS2_CTX *ctx)
{
  Node *x;

  ctx->m_cb = malloc(sizeof(MCB) * MCB_MAX);
  memset(ctx->m_cb, 0, sizeof(MCB) * MCB_MAX);

  ctx->m_cur = -1;
  x = alloc_m(ctx);
  if (x == NULL) {
    return(-1);
  }
  ctx->root = alloc_1(ctx);
  return(1);
}

int regist(pTHX_ XS2_CTX *ctx, char *ip, int mask)
{
  in_addr_t addr;
  Node *p;
  int i;

  if (mask < 1 || mask > 32)
    return(-1);

  /*inet_pton(AF_INET, ip, &addr);*/
  _inet_aton2(ip, &addr);
  /* printf("%0x\n", addr); */
 
  p = ctx->root;
  for (i=0; i<mask; i++) {
    if (addr & bits[i]) {
      if (p->one == NULL) {
	/* alloc */
	p->one = alloc_1(ctx);
      }
      if (p->one) {
	p = p->one;
      } else {
	return(-1);
      }
      /* printf("%x\n", p); */
    } else {
      if (p->zero == NULL) {
	/* alloc */
	p->zero = alloc_1(ctx);
      }
      if (p->zero) {
	p = p->zero;
      } else {
	return(-1);
      }
      /* printf("%x\n", p); */
    }
  }
  p->code = "1";
  /* printf("%s/%d\n", ip, mask); */
  return(1);
}

int match_ip(pTHX_ XS2_CTX * ctx, char *ip, char *match)
{
  in_addr_t addr, m_addr;
  Node *p;
  int i;

  _inet_aton2(ip, &addr);
  m_addr = 0;
 
  p = ctx->root;
  for (i=0; i<32; i++) {
    if (p->code) {
      if (match != NULL)
	print_ip(m_addr, i, match);
      return 1;
    }
    if (addr & bits[i]) {
      m_addr |= bits[i];
      if (p->one) {
	p = p->one;
	continue;
      }
    } else {
      if (p->zero) {
	p = p->zero;
	continue;
      }
    }
    return 0;
  }
}

int _inet_aton2(char *ip, in_addr_t *addr)
{
  char buf[4][4];
  unsigned int pt[4];
  int i, j;
  char c;

  for (i=0; i<4; i++) {
    for (j=0; j<4; j++) {
      c = *(ip++);
      if (c >= '0' && c <= '9')
	buf[i][j] = c;
      else
	break;
    }
    buf[i][j] = '\0';
    pt[i] = atoi((char*)&buf[i][0]);
    /* check */
    if (pt[i] < 0 || pt[i] > 255)
      return(-1);
  }
  *addr = (pt[0] << 24) |
    ((pt[1] & 0xff)<<16) |
    ((pt[2] & 0xff)<<8) |
    (pt[3] & 0xff);
  return(1);
}

_dump (Node *p, u_int32_t ip, int lvl)
{
  char str[21];
  if (p->code) {
    print_ip(ip, lvl, str);
    printf("%s\n", str);
  }
  if (p->zero) {
    _dump(p->zero, ip, lvl+1);
  }
  if (p->one) {
    _dump(p->one, ip|bits[lvl], lvl+1);
  }
}

int print_ip (u_int32_t ip, int lvl, char *str)
{
  if (str != NULL)
    return(snprintf(str, 20, "%u.%u.%u.%u/%d",
		    (ip & 0xff000000) >> 24,
		    (ip & 0x00ff0000) >> 16,
		    (ip & 0x0000ff00) >> 8,
		    ip & 0x000000ff, lvl));
}


MODULE = Net::IP::Match::XS2		PACKAGE = Net::IP::Match::XS2

PROTOTYPES: DISABLE

void
new(class)
    SV* class

    PREINIT:
        XS2_CTX* ctx;
    PPCODE:
        STRLEN len;
        char *sclass = SvPV(class, len);
	int ret;
#if PVER >= 5008008
        Newx(ctx, 1, XS2_CTX);
#else
        Newz(0, ctx, 1, XS2_CTX);
#endif
        ret = init(aTHX_ ctx);
        if (ret) {
            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), sclass, ctx);
            XSRETURN(1);
        } else {
            Safefree(ctx);
            XSRETURN_UNDEF;
        }

void
add(self, net, mask)
     SV* self
     SV* net
     SV* mask

     PREINIT:
	XS2_CTX* ctx;
	STRLEN len;
	char *s = SvPVbyte(net, len);
	int i = SvIV(mask);

     PPCODE:
	if (!SvROK(self)) {
	    XSRETURN_UNDEF;
	} else {
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	}
	if (regist(aTHX_ ctx, s, i) > 0) {
	    XSRETURN(1);
	} else {
	    XSRETURN_UNDEF;
	}

void
DESTROY(self)
	SV* self
     CODE:
	if (SvROK(self)) {
	  XS2_CTX* ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	  free_m(aTHX_ ctx);
	  Safefree(ctx);
	}

void
match_ip(self, ip)
	SV* self
	SV* ip
     PREINIT:
	XS2_CTX* ctx;
	STRLEN len;
	char out[21];
     PPCODE:
	if (!SvROK(self)) {
	    XSRETURN_UNDEF;
	} else {
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	}
	if (match_ip(aTHX_ ctx, SvPVbyte(ip, len), out) > 0) {
	  ST(0) = newSVpv(out, 0);
	  sv_2mortal(ST(0));
	  XSRETURN(1);
	} else {
	  XSRETURN_UNDEF;
	}

