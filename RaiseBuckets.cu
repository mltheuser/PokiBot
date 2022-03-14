#include "RaiseBuckets.cuh"
#include <stdexcept>

std::vector<std::pair<char, float>> getRaises() {
    std::vector<std::pair<char, float>> raisePairs;
    raisePairs.reserve(raiseSizes.size());

    for (float raiseSize : raiseSizes) {
        raisePairs.push_back(std::pair<char, float>('r', raiseSize));
    }

    return raisePairs;
}

float getRaise(float raise) {
    if (raiseSizes.size() == 0) {
        throw std::invalid_argument("getRaise is empty");
    }
    else if (raiseSizes.size() == 1) {
        return raiseSizes[0];
    } else {

        //steht zwar lower, c++ ist aber dumm
        std::vector<float>::const_iterator upper = std::lower_bound(raiseSizes.begin(), raiseSizes.end(), raise);

        if (upper == raiseSizes.begin()) {
            return *upper;
        }
        else {
            std::vector<float>::const_iterator lower = upper - 1;

            if (*upper - raise < raise - *lower) {
                return *upper;
            }
            else {
                return *lower;
            }
        }
    }
}