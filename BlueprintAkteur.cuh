#ifndef __BlueprintAkteur__
#define __BlueprintAkteur__

#include <tuple>
#include <vector>

#include "Template.cuh"
#include "Akteur.cuh"

class BlueprintAkteur : public Akteur {
public:
    Template* schablone;

    ~BlueprintAkteur();
    BlueprintAkteur(std::string folder, std::string fileName);
    std::pair<char, float> act(InformationSet* informationSet) override;
};

#endif
