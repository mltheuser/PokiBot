import matplotlib.pyplot as plt
import numpy as np

kernel_1 = [51759.478000, 51802.154000, 85638.475000, 454621.460000]
kernel_2 = [775214.966000, 798760.651000, 837142.145000, 2822078.250000]
kernel_3 = [695506.629000, 694289.403000, 698649.707000, 2023888.170000]
cpu_1 = [780.046000, 877.067000, 943.578000, 1615.920000]
cpu_2 = [388757.382000, 445888.220000, 912115.569000, 6717742.650000]
cpu_3 = [108268.045000, 158025.810000, 329019.494000, 2635175.990000]
memcpy_1 = [26600.096000, 25710.431000, 24379.406000, 44553.080000]

sums = []

#for x in range(4):
#    sums[x] = kernel_1[x] + kernel_2[x] + kernel_3[x] + cpu_1[x] + cpu_2[x] + cpu_3[x] + memcpy_1[x]

sums = np.add(kernel_1, kernel_2)
sums = np.add(sums, kernel_3)
sums = np.add(sums, cpu_1)
sums = np.add(sums, cpu_2)
sums = np.add(sums, cpu_3)
sums = np.add(sums, memcpy_1)

for x in range(4):
    kernel_1[x] = (kernel_1[x] / sums[x]) * 100
    kernel_2[x] = (kernel_2[x] / sums[x]) * 100
    kernel_3[x] = (kernel_3[x] / sums[x]) * 100

    cpu_1[x] = (cpu_1[x] / sums[x]) * 100
    cpu_2[x] = (cpu_2[x] / sums[x]) * 100
    cpu_3[x] = (cpu_3[x] / sums[x]) * 100
    memcpy_1[x] = (memcpy_1[x] / sums[x]) * 100

raise_size = [1, 2, 3, 4]

for x in range(4):
    print(kernel_1[x])
    print(kernel_2[x])
    print(kernel_3[x])
    print(cpu_1[x])
    print(cpu_2[x])
    print(cpu_3[x])
    print(memcpy_1[x])

plt.plot(raise_size, kernel_1, label="kernel_1")
plt.plot(raise_size, kernel_1, label="kernel_1")
plt.plot(raise_size, kernel_1, label="kernel_1")
plt.plot(raise_size, cpu_1, label="card evaluator")
plt.plot(raise_size, cpu_2, label="read")
plt.plot(raise_size, cpu_3, label="write")
plt.plot(raise_size, memcpy_1, label="memcpy_1")

plt.xticks([1, 2, 3, 4], ['{ 1 }', '{ 1, 5 }', '{ 1, 5, 10 }', '{ 1, 5, 10, 25 }'])
plt.xlabel('Raise sizes')
plt.ylabel('% runtime/Iteration')
plt.title('Runtime Aufschluesselung')
plt.legend()
plt.savefig('runtimeAufschluesselung.pdf')
plt.savefig('runtimeAufschluesselung.png')
plt.show()
