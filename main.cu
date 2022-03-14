
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#include "Trainer.cuh"

#include <cstdio>
#include <vector>

void clearFiles() {
    std::remove("blueprint_buckets_0");
    std::remove("blueprint_buckets_1");
    std::remove("blueprint_buckets_2");
    std::remove("blueprint_buckets_3");

    std::remove("blueprint00");
    std::remove("blueprint01");
    std::remove("blueprint10");
    std::remove("blueprint11");
    std::remove("blueprint20");
    std::remove("blueprint21");
    std::remove("blueprint30");
    std::remove("blueprint31");
}

int main() {
    srand(0);

    bool running = true;
    char action;
    int iterations;
    int mode;

    while (running) {
        std::cout << "What do you want to do? c(learfiles), t(rain), p(lay), e(xit) ";
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
            trainer.trainSequentiell(iterations);
        } else {
            std::cout << "Ungültige Eingaben";
        }
    }
}
