import matplotlib.pyplot as plt

#cpu_sum = [23081, 288882, 2514916]
#gpu_970_sum = [168408, 188554, 284472]
#gpu_1080_sum = []

cpu = [0.23081, 2.88882, 25.1492, 163.901]
gpu_970 = [1.68408, 1.88554, 2.84472, 10.2523]
gpu_2070_1 = [1.46658, 1.85718, 3.18167, 11.1196]
gpu_2070_2 = [1.67635, 1.87017, 3.21679, 10.7487]
gpu_2070_3 = [1.40923, 1.79162, 2.99277, 10.3653]

gpu_2070 = [
    (gpu_2070_1[0] + gpu_2070_2[0] + gpu_2070_3[0]) / 3,
    (gpu_2070_1[1] + gpu_2070_2[1] + gpu_2070_3[1]) / 3,
    (gpu_2070_1[2] + gpu_2070_2[2] + gpu_2070_3[2]) / 3,
    (gpu_2070_1[3] + gpu_2070_2[3] + gpu_2070_3[3]) / 3,
            ]

raise_size = [1, 2, 3, 4]

plt.plot(raise_size, cpu, label="INTEL I7-9700K @3.6GHz")
plt.plot(raise_size, gpu_970, label="NVIDIA GEFORCE GTX 970 (INTEL I7-9700K @3.6GHz)")
plt.plot(raise_size, gpu_2070, label="RTX 2070 (RYZEN 5 2600)")

plt.xticks([1, 2, 3, 4], ['{ 1 }', '{ 1, 2 }', '{ 1, 2, 4 }', '{ 1, 2, 4, 8 }'])
plt.xlabel('Raise sizes')
plt.ylabel('Time(ms)/Iteration')
plt.ylim([0, 30])
plt.title('Runtime progression')
plt.legend()
plt.savefig('runtimeProgression.pdf')
plt.show()
