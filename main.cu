
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#include "Trainer.cuh"
#include "GameMaster.cuh"

#include <cstdio>
#include <vector>
#include <time.h>
#include <string>

void clearFiles(std::string prefix) {
    std::remove((prefix + "_blueprint_buckets_0").c_str());
    std::remove((prefix + "_blueprint_buckets_1").c_str());
    std::remove((prefix + "_blueprint_buckets_2").c_str());
    std::remove((prefix + "_blueprint_buckets_3").c_str());

    std::remove((prefix + "_blueprint00").c_str());
    std::remove((prefix + "_blueprint01").c_str());
    std::remove((prefix + "_blueprint10").c_str());
    std::remove((prefix + "_blueprint11").c_str());
    std::remove((prefix + "_blueprint20").c_str());
    std::remove((prefix + "_blueprint21").c_str());
    std::remove((prefix + "_blueprint30").c_str());
    std::remove((prefix + "_blueprint31").c_str());
}

int main() {
    srand(0);

    bool running = true;
    char action;
    int iterations;
    char device;
    clock_t init, train;

    while (running) {
        std::cout << "What do you want to do? c(learfiles), t(rain), p(lay), e(xit) ";
        std::cin >> action;

        if (action == 'e') {
            running = false;
        }
        else if (action == 'c') {
            std::cout << "device: cpu(0), gpu(1), all(2)";
            std::cin >> device;
            if (device == '0') {
                clearFiles("cpu");
            }
            else if (device == '1') {
                clearFiles("gpu");
            }
            else if (device == '2') {
                clearFiles("cpu");
                clearFiles("gpu");
            }
            else {
                std::cout << "deletion aborted" << std::endl;
            }
        }
        else if (action == 't') {
            std::cout << "device: (c)pu, (g)pu: ";
            std::cin >> device;
            if (device == 'c') {
                std::cout << "Input number of iterations: ";
                std::cin >> iterations;
                init = clock();
                TexasHoldemTrainer trainer = TexasHoldemTrainer("blueprint");
                init = clock() - init;
                trainer.trainSequentiell(iterations, false);
                train = clock() - init;
                std::cout << "init: " << init << " train " << iterations << " iterations: " << train << " (" << train / static_cast<double>(iterations) << " pro iteration)" << std::endl;
            }
            else {
                std::cout << "Input number of iterations: ";
                std::cin >> iterations;
                init = clock();
                TexasHoldemTrainer trainer = TexasHoldemTrainer("blueprint");
                init = clock() - init;
                trainer.trainSequentiell(iterations, true);
                train = clock() - init;
                std::cout << "init: " << init << " train " << iterations << " iterations: " << train << " (" << train / static_cast<double>(iterations) << " pro iteration)" << std::endl;
            }
            
        } else if (action == 'p') {
            std::cout << "Input number of iterations: ";
            std::cin >> iterations;
            GameMaster gameMaster = GameMaster("blueprint");
            gameMaster.playBlueprintVersusRandom(iterations);
        } else {
            std::cout << "Ungültige Eingaben";
        }
    }
}
