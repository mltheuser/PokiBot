#ifndef __ManualAkteur__
#define __ManualAkteur__

#include <tuple>
#include <vector>

#include "Template.cuh"
#include "Akteur.cuh"

class ManualAkteur : public Akteur {
public:
    Template* schablone;

    ~ManualAkteur();
    ManualAkteur(std::string folder, std::string fileName);
    std::pair<char, float> act(InformationSet* informationSet) override;
};

#endif