#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "read.h"

extern uint64_t add_all(uint64_t, float*, uint64_t);
extern uint64_t gauss(float*, float*, uint64_t, uint64_t);
extern uint64_t one_diagonal(uint64_t, float*, uint64_t);
extern void extransw(float*, float*, uint64_t, uint64_t);
extern void conf_sse();
extern uint64_t find_nevyaz(float*, float*, float*, uint64_t, uint64_t);
extern float determinant(float*, float*, uint64_t, uint64_t);
extern uint64_t determinant_fpu(long double*, float*, uint64_t, uint64_t);

char fname[255];
float* equ;
float* answ;
float* nevyaz;
//float determ = 0;
long double determ = 0.0f;

void main(void){
	conf_sse();

	uint64_t allocsize;
	char input_type;
	printf("Select the input type(f/t(f for file, t for terminal)):");
	scanf("%c", &input_type);
	printf("\n");
	uint64_t size;
	if(input_type == 'f'){
		printf("Input the file name:");
		scanf("%s", fname);
		printf("\n");
		FILE* file = fopen(fname, "r+");
		fscanf(file, "%ld", &size);
		allocsize = readfile(file, size, &equ);
		//printf("%ld\n", size);
		printf("Initial matrix\n");
		for(uint64_t i = 0; i < size; i++){
			for(uint64_t j = 0; j < allocsize; j++){
				printf("%f ", equ[i*allocsize+j]);
			}
			printf("\n");
		}
		//return;
	}else if(input_type == 't'){
		allocsize = readterm(&size, &equ);
		printf("Initial matrix\n");
		for(uint64_t i = 0; i < size; i++){
			for(uint64_t j = 0; j < allocsize; j++){
				printf("%f ", equ[i*allocsize+j]);
			}
			printf("\n");
		}
		//return;		
	}else{
		printf("Wrong input type!\n");
		return;
	}

	float* equ_copy = (float*)malloc(size*allocsize*4);
	memcpy(equ_copy, equ, size*allocsize*4);


	// if(swap_rows(size, equ, allocsize)){
	// 	printf("all elements are zero!\n");
	// 	return;
	// }
	if(add_all(size, equ, allocsize)){
		printf("all elements are zero!\n");
		return;
	}
	printf("\n");
	float* equ_det = (float*)malloc(size*allocsize*4);
	memcpy(equ_det, equ, size*allocsize*4);

	printf("Matrix after zero-elimination\n");
	for(uint64_t i = 0; i < size; i++){
		for(uint64_t j = 0; j < allocsize; j++){
			printf("%f ", equ[i*allocsize+j]);
		}
		printf("\n");
	}
	printf("\n");
	answ = (float*)malloc(allocsize*4);
	nevyaz = (float*)malloc(allocsize*4);
	gauss(answ, equ, allocsize, size);
	one_diagonal(size, equ, allocsize);
	extransw(answ, equ, allocsize, size);
	find_nevyaz(nevyaz, equ_copy, answ, size, allocsize);
	determinant_fpu(&determ, equ_det, allocsize, size);


	// for(uint64_t i = 0; i < size; i++){
	// 	for(uint64_t j = 0; j < allocsize; j++){
	// 		printf("%f ", equ_copy[i*allocsize+j]);
	// 	}
	// 	printf("\n");
	// }
	// printf("\n");

	printf("Matrix after Gauss\n");
	for(uint64_t i = 0; i < size; i++){
		for(uint64_t j = 0; j < allocsize; j++){
			printf("%f ", equ[i*allocsize+j]);
		}
		printf("\n");
	}
	printf("\n");

	// for(uint64_t i = 0; i < size; i++){
	// 	for(uint64_t j = 0; j < allocsize; j++){
	// 		printf("%f ", equ_det[i*allocsize+j]);
	// 	}
	// 	printf("\n");
	// }
	// printf("\n");


	for(uint64_t i = 0; i < size; i++){
		printf("x%ld=%f\n", i+1, answ[i]);
	}
	printf("\n");
	for(uint64_t i = 0; i < size; i++){
		printf("r%ld=%f\n", i+1, nevyaz[i]);
	}
	printf("\n");
	printf("determinant: %Lf\n", determ);
	
}
