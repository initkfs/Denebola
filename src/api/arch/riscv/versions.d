module api.arch.riscv.versions;

version (Riscv32)
{
    enum __isRiscv = true;
}

version (Riscv64)
{
    enum __isRiscv = true;
}

version (Esp32C3)
{
    enum __isC3 = true;
}
