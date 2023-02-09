uint64_t readfile(FILE* file, uint64_t size, float** equ){
	uint64_t allocsize;
	if(size+1 <= 8){
		allocsize = 8;
	}else if(size+1 <= 16){
		allocsize = 16;
	}else if(size+1 <= 24){
		allocsize = 24;
	}
	(*equ) = (float*)malloc(size*allocsize*4);
	int ret;

	for(uint64_t i = 0; i < size; i++){
		for(uint64_t j = 0; j < allocsize; j++){
			if(j <= size){
				ret = fscanf(file, "%f", (*equ)+i*allocsize+j);
				if(ret != 1 && ret != -4 && ret != -1){
					printf("Not a float value supplied in the file\n");
					exit(0);
				}
			}else{
				*((*equ)+i*allocsize+j) = 0.0f;
			}
		}
	}

	return allocsize;

}

uint64_t readterm(uint64_t* size, float** equ){
	uint64_t allocsize;
	printf("Size: ");
	scanf("%ld", size);
	if((*size)+1 <= 8){
		allocsize = 8;
	}else if((*size)+1 <= 16){
		allocsize = 16;
	}else if((*size)+1 <= 24){
		allocsize = 24;
	}
	(*equ) = (float*)malloc((*size)*allocsize*4);
	int ret;
	for(uint64_t i = 0; i < (*size); i++){
		for(uint64_t j = 0; j < allocsize; j++){
			if(j <= (*size)){
				ret = scanf("%f", (*equ)+i*allocsize+j);
				if(ret != 1 && ret != -4 && ret != -1){
					printf("Not a float value supplied in the file\n");
					exit(0);
				}
			}else{
				*((*equ)+i*allocsize+j) = 0.0f;
			}
		}
	}
	return allocsize;
}