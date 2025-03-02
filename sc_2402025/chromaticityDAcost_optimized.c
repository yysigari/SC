#include "mex.h"

// Declare the optimized C function
extern void chromaticityDAcost_optimized(double* k, double* RING, int* sext_indexes, int N, double* F);

// MATLAB wrapper function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Check inputs
    if (nrhs != 3) {
        mexErrMsgIdAndTxt("MATLAB:chromaticityDAcost_optimized:nrhs", "Three inputs required.");
    }
    if (nlhs != 1) {
        mexErrMsgIdAndTxt("MATLAB:chromaticityDAcost_optimized:nlhs", "One output required.");
    }

    // Get inputs: k, RING, sext_indexes
    double* k = mxGetPr(prhs[0]);
    double* RING = mxGetPr(prhs[1]);
    int* sext_indexes = (int*) mxGetData(prhs[2]);
    int N = mxGetNumberOfElements(prhs[0]);  // Length of sext_indexes

    // Allocate output array for the objective function vector
    plhs[0] = mxCreateDoubleMatrix(1, 2, mxREAL);
    double* F = mxGetPr(plhs[0]);

    // Call the optimized C function
    chromaticityDAcost_optimized(k, RING, sext_indexes, N, F);
}
