#include "RaiseBuckets.cuh"

std::vector<std::pair<char, float>> getRaises() {
    std::vector<std::pair<char, float>> raisePairs;
    raisePairs.reserve(raiseSizes.size());

    for (float raiseSize : raiseSizes) {
        raisePairs.push_back(std::pair<char, float>('r', raiseSize));
    }

    return raisePairs;
}

float getRaise(float raise) {
    //steht zwar lower, c++ ist aber dumm
    std::vector<float>::const_iterator upper = std::lower_bound(raiseSizes.begin(), raiseSizes.end(), raise);
    std::vector<float>::const_iterator lower = upper - 1;

    if (*upper - raise < raise - *lower) {
        return *upper;
    }
    else {
        return *lower;
    }
}