module api.arch.riscv.esp32c3.c3_flash;

import Volatile = api.arch.riscv.rcom.rcom_volatile;

/**
 * Authors: initkfs
 */

bool c3FlashInit()
{
    uint32_t sizeBytes = 4 * 1024 * 1024;

    auto ret = esp_rom_spiflash_config_param(
        0, // chip_id
        sizeBytes, // chip_size
        64 * 1024, // block_size (64 KB)
        256, // page_size (256 B)
        0xFFFF, // status_mask
        40 * 1000 * 1000 // hz (40 MHz)

        

    );
    return ret == esp_rom_spiflash_result_t.ESP_ROM_SPIFLASH_RESULT_OK;
}

bool c3FlashReadMap(size_t addr, out size_t dest)
{
    //TODO check align
    auto ptr = cast(size_t*)(0x3C00_0000 + addr);
    dest = Volatile.load(ptr);
    return true;
}

bool c3FlashRead(size_t addr, out size_t dest, size_t len)
{
    auto ret = esp_rom_spiflash_read(addr, &dest, cast(int) len);
    return ret == esp_rom_spiflash_result_t.ESP_ROM_SPIFLASH_RESULT_OK;
}

enum esp_rom_spiflash_result_t
{
    ESP_ROM_SPIFLASH_RESULT_OK, // 0
    ESP_ROM_SPIFLASH_RESULT_ERR, // 1
    ESP_ROM_SPIFLASH_RESULT_TIMEOUT // 2
}

alias uint32_t = uint;
/**
  * @param  uint32_t src_addr : Address to read, should be 4 bytes aligned.
  * @param  uint32_t *dest : The buf to read the data.
  * @param  uint32_t len : Length to read, should be 4 bytes aligned.
  *
  * @return ESP_ROM_SPIFLASH_RESULT_OK : Read OK.
  *         ESP_ROM_SPIFLASH_RESULT_ERR : Read error.
  *         ESP_ROM_SPIFLASH_RESULT_TIMEOUT : Read timeout.
  */
extern (C):

esp_rom_spiflash_result_t esp_rom_spiflash_read(uint src_addr, uint* dest, int len);

/**
  * @param  uint32_t ishspi: 0 for spi, 1 for hspi, flash pad decided by strapping
  *              else, bit[5:0] spiclk, bit[11:6] spiq, bit[17:12] spid, bit[23:18] spics0, bit[29:24] spihd
  *
  * @param  uint8_t legacy: always keeping false.
  *
  * @return None
  */
void esp_rom_spiflash_attach(uint ishspi, bool legacy);

uint spi_flash_get_chip_size();

esp_rom_spiflash_result_t esp_rom_spiflash_config_param(uint32_t deviceId, uint32_t chip_size, uint32_t block_size,
    uint32_t sector_size, uint32_t page_size, uint32_t status_mask);
