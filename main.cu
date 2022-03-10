
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#include "Trainer.cuh"

#include <cstdio>
#include <vector>

void clearFiles(std::string prefix) {
    std::remove((std::string() + prefix + "_buckets_0").c_str());
    std::remove((std::string() + prefix + "_buckets_1").c_str());
    std::remove((std::string() + prefix + "_buckets_2").c_str());
    std::remove((std::string() + prefix + "_buckets_3").c_str());

    std::remove((std::string() + prefix + "_00").c_str());
    std::remove((std::string() + prefix + "_01").c_str());
    std::remove((std::string() + prefix + "_10").c_str());
    std::remove((std::string() + prefix + "_11").c_str());
    std::remove((std::string() + prefix + "_20").c_str());
    std::remove((std::string() + prefix + "_21").c_str());
    std::remove((std::string() + prefix + "_30").c_str());
    std::remove((std::string() + prefix + "_31").c_str());
}

int main() {
    srand(0);

    bool running = true;
    char action;
    int iterations;
    int mode;

    while (running) {
        std::cout << "What do you want to do? b(enchmark), c(learfiles), t(rain), p(lay), e(xit) ";
        std::cin >> action;

        if (action == 'e') {
            running = false;
        }
        else if (action == 'c') {
            // clearFiles();
        }
        else if (action == 't') {
            std::cout << "Input number of iterations";
            std::cin >> iterations;
            TexasHoldemTrainer trainer = TexasHoldemTrainer("blueprint");
            trainer.trainGpu(iterations);
        }
        else if (action == 'b') {
            std::cout << "Input number of iterations";
            std::cin >> iterations;
            clock_t t1, t2;
            clearFiles("benchmark");
            {
            TexasHoldemTrainer trainer = TexasHoldemTrainer("benchmark");
            t1 = clock();
            trainer.trainGpu(iterations);
            t1 = clock() - t1;
            clearFiles("benchmark");
            }
            {
            TexasHoldemTrainer trainer = TexasHoldemTrainer("benchmark");
            t2 = clock();
            trainer.trainSequentiell(iterations);
            }
            t2 = clock() - t2;
            std::cout << "gpu: " << t1 << " sequentiell: " << t2 << std::endl;
        } else {
            std::cout << "Ungültige Eingaben";
        }
    }
}
