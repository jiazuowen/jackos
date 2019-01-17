#include "bootpack.h"

#define SHEET_USE		1

struct SHTCTL* shtctl_init(struct MEMMAN* memman, unsigned char* vram, int xsize, int ysize)
{
    struct SHTCTL* ctl;
    int i;
    ctl = (struct SHTCTL*)memman_alloc_4k(memman, sizeof(struct SHTCTL));
    if (ctl == 0) {
        goto err;
    }
    ctl->vram = vram;
    ctl->xsize = xsize;
    ctl->ysize = ysize;
    ctl->top = -1; /*一个SHEET都没有*/
    for (i = 0; i < MAX_SHEETS; i++) {
        ctl->sheets0[i].flags = 0; /*标记为未使用*/
    }
err:
    return ctl;
}
struct SHEET* sheet_alloc(struct SHTCTL* ctl)
{
    struct SHEET* sht;
    int i;
    for (i = 0; i < MAX_SHEETS; i++) {
        if (ctl->sheets0[i].flags == 0) {
            sht = &ctl->sheets0[i];
            sht->flags = SHEET_USE; /*标记为正在使用*/
            sht->height = -1; /*隐藏*/
            return sht;
        }
    }
    return 0; /*所用的SHEET都在使用中*/
}

/*
设置图层缓冲区大小和透明色
*/
void sheet_setbuf(struct SHEET* sht, unsigned char* buf, int xsize, int ysize, int col_inv)
{
    sht->buf = buf;
    sht->bxsize = xsize;
    sht->bysize = ysize;
    sht->col_inv = col_inv;
    return;
}

void sheet_updown(struct SHTCTL* ctl, struct SHEET* sht, int height)
{
    int h, old = sht->height; /*存储设置前的高度信息*/ 
    /*设置的高度过低或过高，修正*/
    if (height > ctl->top + 1) {
        height = ctl->top +1;
    }
    if (height < -1) {
        height = -1;
    }
    sht->height = height; /*高度设置*/

    /*对sheets[]重新排列*/
    if (old > height) {
        /*把中间的往上提*/
        if (height >= 0) {
            for (h = old; h > height; h--) {
                ctl->sheets[h] = ctl->sheets[h-1];
                ctl->sheets[h]->height = h;
            }
            ctl->sheets[height] = sht;
        } else { /*隐藏*/
            if (ctl->top > old) {
                /*把上面的降下来*/
                for (h = old; h < ctl->top; h++) {
                    ctl->sheets[h] = ctl->sheets[h+1];
                    ctl->sheets[h]->height = h;
                }
            }
            ctl->top--; /*因为图层少了一个，所以top减少一个*/
        }
        sheet_refresh(ctl); /*按照图层信息重新绘制画面*/
    } else if (old < height) { /*比以前高了*/
        if (old >= 0) {
            /*把中间的拉下去*/
            for (h = old; h < height; h++) {
                ctl->sheets[h] = ctl->sheets[h+1];
                ctl->sheets[h] = h;
            }
            ctl->sheets[height] = sht;
        } else { /*由隐藏转为显示*/
            /*将已在上面的往上提*/
            for (h = ctl->top; h >= height; h--) {
                ctl->sheets[h+1] = ctl->sheets[h];
                ctl->sheets[h+1]->height = h+1;
            }
            ctl->sheets[height] = sht;
            ctl->top++; /*增加了一个图层*/
        }
        sheet_refresh(ctl);
    }
    return;
}

void sheet_refresh(struct SHTCTL* ctl)
{
    int h, bx, by, vx, vy;
    unsigned char *buf, c, *vram = ctl->vram;
    struct SHEET *sht;
    for (h = 0; h <= ctl->top; h++) {
        sht = ctl->sheets[h];
        buf = sht->buf;
        for (by = 0; by < sht->bysize; by++) {
            vy = sht->vy0 + by;
            for (bx = 0; bx < sht->bxsize; bx++) {
                vx = sht->vx0 + bx;
                c = buf[by * sht->bxsize + bx];
                if (c != sht->col_inv) {
                    vram[vy * ctl->xsize + vx] = c;
                }
            }
        }
    }
    return;
}

void sheet_slide(struct SHTCTL* ctl, struct SHEET* sht, int vx0, int vy0)
{
    sht->vx0 = vx0;
    sht->vy0 = vy0;
    if (sht->height >= 0) { /*如果正在显示*/
        sheet_refresh(ctl); /*按照新图层的信息刷新画面*/
    }
    return;
}

void sheet_free(struct SHTCTL* ctl, struct SHEET* sht)
{
    if (sht->height >= 0) {
        sheet_updown(ctl, sht, -1); /*先设置为隐藏*/
    }
    sht->flags = 0; /*未使用标志*/
    return;
}