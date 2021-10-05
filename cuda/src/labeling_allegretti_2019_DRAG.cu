// Copyright (c) 2020, the YACCLAB contributors, as 
// shown by the AUTHORS file. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include <opencv2/cudafeatures2d.hpp>

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "labeling_algorithms.h"
#include "register.h"


#define BLOCK_ROWS 16
#define BLOCK_COLS 16

using namespace cv;

namespace {

	// Only use it with unsigned numeric types
	template <typename T>
	__device__ __forceinline__ unsigned char HasBit(T bitmap, unsigned char pos) {
		return (bitmap >> pos) & 1;
	}

	//__device__ __forceinline__ void SetBit(unsigned char &bitmap, unsigned char pos) {
	//	bitmap |= (1 << pos);
	//}

	// Returns the root index of the UFTree
	__device__ unsigned Find(const int *s_buf, unsigned n) {
		while (s_buf[n] != n) {
			n = s_buf[n];
		}
		return n;
	}


	// Merges the UFTrees of a and b, linking one root to the other
	__device__ void Union(int *s_buf, unsigned a, unsigned b) {

		bool done;

		do {

			a = Find(s_buf, a);
			b = Find(s_buf, b);

			if (a < b) {
				int old = atomicMin(s_buf + b, a);
				done = (old == b);
				b = old;
			}
			else if (b < a) {
				int old = atomicMin(s_buf + a, b);
				done = (old == a);
				a = old;
			}
			else {
				done = true;
			}

		} while (!done);

	}


	__global__ void InitLabeling(cuda::PtrStepSzi labels) {
		unsigned row = (blockIdx.y * BLOCK_ROWS + threadIdx.y) * 2;
		unsigned col = (blockIdx.x * BLOCK_COLS + threadIdx.x) * 2;
		unsigned labels_index = row * (labels.step / labels.elem_size) + col;

		if (row < labels.rows && col < labels.cols) {
			labels[labels_index] = labels_index;
		}
	}

	__global__ void Merge(const cuda::PtrStepSzb img, cuda::PtrStepSzi labels) {

		unsigned row = (blockIdx.y * BLOCK_ROWS + threadIdx.y) * 2;
		unsigned col = (blockIdx.x * BLOCK_COLS + threadIdx.x) * 2;
		unsigned img_index = row * img.step + col;
		unsigned labels_index = row * (labels.step / labels.elem_size) + col;

		if (row < labels.rows && col < labels.cols) {

#define CONDITION_B col>0 && row>1 && img.data[img_index - 2 * img.step - 1]
#define CONDITION_C row>1 && img.data[img_index - 2 * img.step]
#define CONDITION_D col+1<img.cols && row>1 && img.data[img_index - 2 * img.step + 1]
#define CONDITION_E col+2<img.cols && row>1 && img.data[img_index - 2 * img.step + 2]

#define CONDITION_G col>1 && row>0 && img.data[img_index - img.step - 2]
#define CONDITION_H col>0 && row>0 && img.data[img_index - img.step - 1]
#define CONDITION_I row>0 && img.data[img_index - img.step]
#define CONDITION_J col+1<img.step && row>0 && img.data[img_index - img.step + 1]
#define CONDITION_K col+2<img.step && row>0 && img.data[img_index - img.step + 2]

#define CONDITION_M col>1 && img.data[img_index - 2]
#define CONDITION_N col>0 && img.data[img_index - 1]
#define CONDITION_O img.data[img_index]
#define CONDITION_P col+1<img.step && img.data[img_index + 1]

#define CONDITION_R col>0 && row+1<img.rows && img.data[img_index + img.step - 1]
#define CONDITION_S row+1<img.rows && img.data[img_index + img.step]
#define CONDITION_T col+1<img.cols && row+1<img.rows && img.data[img_index + img.step + 1]

			// Action 1: No action
#define ACTION_1  
//			// Action 2: New label (the block has foreground pixels and is not connected to anything else)
#define ACTION_2  
			//Action P: Merge with block P
#define ACTION_3 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) - 2); 
			// Action Q: Merge with block Q
#define ACTION_4 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size));	
			// Action R: Merge with block R
#define ACTION_5 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) + 2); 
			// Action S: Merge with block S
#define ACTION_6 Union(labels.data, labels_index, labels_index - 2);  
			// Action 7: Merge labels of block P and Q
#define ACTION_7 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) - 2); \
			Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size));			
			//Action 8: Merge labels of block P and R
#define ACTION_8 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) - 2); \
			Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) + 2);			
			// Action 9 Merge labels of block P and S
#define ACTION_9 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) - 2); \
			Union(labels.data, labels_index, labels_index - 2);			
			// Action 10 Merge labels of block Q and R
#define ACTION_10 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size)); \
			Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) + 2);			
			// Action 11: Merge labels of block Q and S
#define ACTION_11 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size)); \
			Union(labels.data, labels_index, labels_index - 2);			
			// Action 12: Merge labels of block R and S
#define ACTION_12 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) + 2); \
			Union(labels.data, labels_index, labels_index - 2);			
			// Action 13: not used
#define ACTION_13 
			// Action 14: Merge labels of block P, Q and S
#define ACTION_14 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) - 2); \
			Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size)); \
			Union(labels.data, labels_index, labels_index - 2);		
			//Action 15: Merge labels of block P, R and S
#define ACTION_15 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) - 2); \
			Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) + 2); \
            Union(labels.data, labels_index, labels_index - 2);			
			//Action 16: labels of block Q, R and S
#define ACTION_16 Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size)); \
			Union(labels.data, labels_index, labels_index - 2 * (labels.step / labels.elem_size) + 2); \
			Union(labels.data, labels_index, labels_index - 2);			

#include "labeling_bolelli_2018_drag.inc.h"

#undef ACTION_0
#undef ACTION_2
#undef ACTION_P
#undef ACTION_Q
#undef ACTION_R
#undef ACTION_S
#undef ACTION_7
#undef ACTION_8
#undef ACTION_9
#undef ACTION_10
#undef ACTION_11
#undef ACTION_12
#undef ACTION_13
#undef ACTION_14
#undef ACTION_15
#undef ACTION_16


#undef CONDITION_B
#undef CONDITION_C
#undef CONDITION_D
#undef CONDITION_E

#undef CONDITION_G
#undef CONDITION_H
#undef CONDITION_I
#undef CONDITION_J
#undef CONDITION_K

#undef CONDITION_M
#undef CONDITION_N
#undef CONDITION_O
#undef CONDITION_P

#undef CONDITION_R
#undef CONDITION_S
#undef CONDITION_T

		}
	}

	__global__ void Compression(cuda::PtrStepSzi labels) {

		unsigned row = (blockIdx.y * BLOCK_ROWS + threadIdx.y) * 2;
		unsigned col = (blockIdx.x * BLOCK_COLS + threadIdx.x) * 2;
		unsigned labels_index = row * (labels.step / labels.elem_size) + col;

		if (row < labels.rows && col < labels.cols) {
			labels[labels_index] = Find(labels.data, labels_index);
		}
	}


	__global__ void FinalLabeling(const cuda::PtrStepSzb img, cuda::PtrStepSzi labels) {

		unsigned row = (blockIdx.y * BLOCK_ROWS + threadIdx.y) * 2;
		unsigned col = (blockIdx.x * BLOCK_COLS + threadIdx.x) * 2;
		unsigned labels_index = row * (labels.step / labels.elem_size) + col;
		unsigned img_index = row * (img.step / img.elem_size) + col;

		if (row < labels.rows && col < labels.cols) {

			unsigned int label = labels[labels_index] + 1;

			if (img.data[img_index])
				labels[labels_index] = label;
			else {
				labels[labels_index] = 0;
			}

			if (col + 1 < labels.cols) {
				if (img.data[img_index + 1])
					labels[labels_index + 1] = label;
				else {
					labels[labels_index + 1] = 0;
				}

				if (row + 1 < labels.rows) {
					if (img.data[img_index + img.step + 1])
						labels[labels_index + (labels.step / labels.elem_size) + 1] = label;
					else {
						labels[labels_index + (labels.step / labels.elem_size) + 1] = 0;
					}
				}
			}

			if (row + 1 < labels.rows) {
				if (img.data[img_index + img.step])
					labels[labels_index + (labels.step / labels.elem_size)] = label;
				else {
					labels[labels_index + (labels.step / labels.elem_size)] = 0;
				}
			}

		}

	}

}

class C_DRAG : public GpuLabeling2D<Connectivity2D::CONN_8> {
private:
	dim3 grid_size_;
	dim3 block_size_;

public:
	C_DRAG() {}

	void PerformLabeling() {

		d_img_labels_.create(d_img_.size(), CV_32SC1);

		grid_size_ = dim3((((d_img_.cols + 1) / 2) + BLOCK_COLS - 1) / BLOCK_COLS, (((d_img_.rows + 1) / 2) + BLOCK_ROWS - 1) / BLOCK_ROWS, 1);
		block_size_ = dim3(BLOCK_COLS, BLOCK_ROWS, 1);

		InitLabeling << <grid_size_, block_size_ >> > (d_img_labels_);

		//cuda::GpuMat d_expanded_connections;
		//d_expanded_connections.create(d_connections_.rows * 3, d_connections_.cols * 3, CV_8UC1);
		//ExpandConnections << <grid_size_, block_size_ >> > (d_connections_, d_expanded_connections);
		//Mat1b expanded_connections;
		//d_expanded_connections.download(expanded_connections);
		//d_expanded_connections.release();

		//Mat1i init_labels;
		//d_block_labels_.download(init_labels);

		Merge << <grid_size_, block_size_ >> > (d_img_, d_img_labels_);

		//Mat1i block_info_final;
		//d_img_labels_.download(block_info_final);		

		Compression << <grid_size_, block_size_ >> > (d_img_labels_);

		FinalLabeling << <grid_size_, block_size_ >> > (d_img_, d_img_labels_);

		// d_img_labels_.download(img_labels_);
		cudaDeviceSynchronize();
	}

	void PerformLabelingBlocksize(int x, int y, int z) override {

		d_img_labels_.create(d_img_.size(), CV_32SC1);

		grid_size_ = dim3((((d_img_.cols + 1) / 2) + x - 1) / x, (((d_img_.rows + 1) / 2) + y - 1) / y, 1);
		block_size_ = dim3(x, y, 1);

		BLOCKSIZE_KERNEL(InitLabeling, grid_size_, block_size_, 0, d_img_labels_)

		BLOCKSIZE_KERNEL(Merge, grid_size_, block_size_, 0, d_img_, d_img_labels_)

		BLOCKSIZE_KERNEL(Compression, grid_size_, block_size_, 0, d_img_labels_)

		BLOCKSIZE_KERNEL(FinalLabeling, grid_size_, block_size_, 0, d_img_, d_img_labels_)
	}


private:
	void Alloc() {
		d_img_labels_.create(d_img_.size(), CV_32SC1);
	}

	void Dealloc() {
	}

	double MemoryTransferHostToDevice() {
		perf_.start();
		d_img_.upload(img_);
		perf_.stop();
		return perf_.last();
	}

	void MemoryTransferDeviceToHost() {
		d_img_labels_.download(img_labels_);
	}

	void AllScans() {
		grid_size_ = dim3((((d_img_.cols + 1) / 2) + BLOCK_COLS - 1) / BLOCK_COLS, (((d_img_.rows + 1) / 2) + BLOCK_ROWS - 1) / BLOCK_ROWS, 1);
		block_size_ = dim3(BLOCK_COLS, BLOCK_ROWS, 1);

		InitLabeling << <grid_size_, block_size_ >> > (d_img_labels_);

		//cuda::GpuMat d_expanded_connections;
		//d_expanded_connections.create(d_connections_.rows * 3, d_connections_.cols * 3, CV_8UC1);
		//ExpandConnections << <grid_size_, block_size_ >> > (d_connections_, d_expanded_connections);
		//Mat1b expanded_connections;
		//d_expanded_connections.download(expanded_connections);
		//d_expanded_connections.release();

		//Mat1i init_labels;
		//d_block_labels_.download(init_labels);

		Merge << <grid_size_, block_size_ >> > (d_img_, d_img_labels_);

		//Mat1i block_info_final;
		//d_img_labels_.download(block_info_final);		

		Compression << <grid_size_, block_size_ >> > (d_img_labels_);

		FinalLabeling << <grid_size_, block_size_ >> > (d_img_, d_img_labels_);

		cudaDeviceSynchronize();
	}

public:
	void PerformLabelingWithSteps()
	{
		perf_.start();
		Alloc();
		perf_.stop();
		double alloc_timing = perf_.last();

		perf_.start();
		AllScans();
		perf_.stop();
		perf_.store(Step(StepType::ALL_SCANS), perf_.last());

		perf_.start();
		Dealloc();
		perf_.stop();
		double dealloc_timing = perf_.last();

		perf_.store(Step(StepType::ALLOC_DEALLOC), alloc_timing + dealloc_timing);
	}

};

REGISTER_LABELING(C_DRAG);

REGISTER_KERNELS(C_DRAG, InitLabeling, Merge, Compression, FinalLabeling)