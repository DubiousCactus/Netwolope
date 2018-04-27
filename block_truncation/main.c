#include <stdio.h>
#include <stdlib.h>
#include "ctype.h"
#include <string.h>

#define HI(num) (((num) & 0x0000FF00) << 8) 
#define LO(num) ((num) & 0x000000FF) 

int buffer[28];
int BUFFER_SIZE = 28;

typedef struct _PGMData {
	int row;
	int col;
	int max_gray;
	int **matrix;
} PGMData;


void read_PGM(const char *file_name, PGMData *data);
void skip_comments(FILE *fp);
void deallocate_dynamic_matrix(int **matrix, int row);
int **allocate_dynamic_matrix(int row, int col);
void write_PGM(const char *filename, const PGMData *data);
PGMData* compress_PGM(PGMData *data);
void simulate_data_package(PGMData *data);

int main() {
	PGMData *image;
	read_PGM("buffalo.pgm", image);

	for (int i = 0; i < image->row; i++) {
		for (int j = 0; j < image->col; j++) {
			printf("%d ", image->matrix[i][j]);
		}
		printf("\n");
	}

	/*simulate_data_package(datastruct);

	for (i = 0; i < BUFFER_SIZE; i++)
	{
		printf(" %d", buffer[i]);
	}*/

	compress_PGM(image);

	write_PGM("compressed_buffalo.pgm", image);
	


	
}


void simulate_data_package(PGMData *data) 
{
	int i,j = 0;
	for (i = 0; i < BUFFER_SIZE; i++) {
		buffer[i] = data->matrix[i][j];
	}
}

PGMData* compress_PGM(PGMData *data) 
{
	int temp, i, j, sum = 0;
	for (i = 0; i < data->row; ++i) {
		for (j = 0; j < data->col; ++j) {
			if (j % 64) {
				temp = data->matrix[i][j];
				
				sum = sum + temp;
			}
			sum = 0;
		}
	}

	return data;
}

int **allocate_dynamic_matrix(int row, int col)
{
	int **ret_val;
	int i;

	ret_val = (int **) malloc(sizeof(int *) * row);
	if (ret_val == NULL) {
		perror("memory allocation failure");
		exit(EXIT_FAILURE);
	}

	for (i = 0; i < row; ++i) {
		ret_val[i] = (int *) malloc(sizeof(int) * col);
		if (ret_val[i] == NULL) {
			perror("memory allocation failure");
			exit(EXIT_FAILURE);
		}
	}

	return ret_val;
}

void deallocate_dynamic_matrix(int **matrix, int row)
{
	int i;

	for (i = 0; i < row; ++i)
		free(matrix[i]);
	
	free(matrix);
}

void skip_comments(FILE *fp)
{
	int ch;
	char line[100];
	while ((ch = fgetc(fp)) != EOF && isspace(ch)) {
		;
	}

	if (ch == '#') {
		fgets(line, sizeof(line), fp);
		skip_comments(fp);
	} else {
		fseek(fp, -1, SEEK_CUR);
	}
}

/* For reading */
void read_PGM(const char *file_name, PGMData *data)
{
	FILE *pgmFile;
	char version[3];
	int i, j;
	int lo, hi;
	pgmFile = fopen(file_name, "rb");
	if (pgmFile == NULL) {
		perror("cannot open file to read");
		exit(EXIT_FAILURE);
	}

	fgets(version, sizeof(version), pgmFile);

	if (strcmp(version, "P5")) {
		fprintf(stderr, "Wrong file type!\n");
		exit(EXIT_FAILURE);
	}

	skip_comments(pgmFile);
	fscanf(pgmFile, "%d", &data->col);
	skip_comments(pgmFile);
	fscanf(pgmFile, "%d", &data->row);
	skip_comments(pgmFile);
	fscanf(pgmFile, "%d", &data->max_gray);
	fgetc(pgmFile);

	data->matrix = allocate_dynamic_matrix(data->row, data->col);
	if (data->max_gray > 255) {
		for (i = 0; i < data->row; ++i) {
			for (j = 0; j < data->col; ++j) {
				hi = fgetc(pgmFile);
				lo = fgetc(pgmFile);
				data->matrix[i][j] = (hi << 8) + lo;
			}
		}
	} else {
		for (i = 0; i < data->row; ++i) {
			for (j = 0; j < data->col; ++j) {
				lo = fgetc(pgmFile);
				data->matrix[i][j] = lo;
			}
		}
	}

	fclose(pgmFile);
}

/* And for writing */
void write_PGM(const char *filename, const PGMData *data)
{
	FILE *pgmFile;
	int i, j;
	int hi, lo;

	pgmFile = fopen(filename, "wb");
	if (pgmFile == NULL) {
		perror("cannot open file to write");
		exit(EXIT_FAILURE);
	}

	fprintf(pgmFile, "P5 ");
	fprintf(pgmFile, "%d %d ", data->col, data->row);
	fprintf(pgmFile, "%d ", data->max_gray);

	if (data->max_gray > 255) {
		for (i = 0; i < data->row; ++i) {
			for (j = 0; j < data->col; ++j) {
				hi = HI(data->matrix[i][j]);
				lo = LO(data->matrix[i][j]);
				fputc(hi, pgmFile);
				fputc(lo, pgmFile);
			}

		}
	} else {
		for (i = 0; i < data->row; ++i) {
			for (j = 0; j < data->col; ++j) {
				lo = LO(data->matrix[i][j]);
				fputc(lo, pgmFile);
			}
		}
	}

	fclose(pgmFile);
	deallocate_dynamic_matrix(data->matrix, data->row);
}
