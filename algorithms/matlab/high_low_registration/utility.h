/*
 *  utility.h
 *  
 *
 *  Created by Jun Kong on 4/17/14.
 *  Copyright 2014 __MyCompanyName__. All rights reserved.
 *
 */

#if !defined(STDIO)
#define STDIO
#include <stdio.h>
#endif

#if !defined(STDLIB)
#define STDLIB
#include <stdlib.h>
#endif

#if !defined(MATH)
#define MATH
#include <math.h>
#endif



extern int x_size; //col
extern int y_size; //row
extern int z_size; //depth 
extern int volume;


typedef struct 
{
	float x;
	float y;
	float z;
} Fvector3d;

typedef struct 
{
	int x;
	int y;
	int z;
} Ivector3d;


int **Ialloc2d(int i_size,int j_size);
void Ifree2d(int **array,int i_size);

int ***Ialloc3d(int i_size,int j_size,int k_size);
void Ifree3d(int ***array,int k_size,int i_size);

unsigned char ***UCalloc3d(int i_size,int j_size,int k_size);
void UCfree3d(unsigned char ***array,int k_size,int i_size);

float ***Falloc3d(int i_size,int j_size,int k_size);
void Ffree3d(float ***array,int k_size,int i_size);

double ***Dalloc3d(int i_size,int j_size,int k_size);
void Dfree3d(double ***array,int k_size,int i_size);

void Dvec_3dArray(double * V, double *** A);
void D3dArray_vec(double *** A, double * V);

Ivector3d ***Ivector3dalloc3d(int i_size,int j_size,int k_size);
void Ivector3dfree3d(Ivector3d ***array,int k_size,int i_size);

void Ivec_3dArray(int * V, int *** A);
void I3dArray_vec(int *** A, int * V);