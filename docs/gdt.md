# Global Descriptor Table (GDT)

The Global Descriptor Table (GDT) defines the segment descriptors used by the
x86 CPU in protected mode. Statix installs a small GDT before setting
`CR0.PE` and jumping into 32-bit code.

## GDT Structure

The processor locates the GDT through the GDTR register, which stores:

- a 16-bit size field (table size minus 1)
- a 32-bit linear base address

Descriptor 0 is required to be the null descriptor.

## Descriptor Bitwise Layout

Each descriptor is 8 bytes wide:

| Byte Index | Bit Scope | Target Field | Field Scope | Functional Description |
| :--- | :--- | :--- | :--- | :--- |
| **0 - 1** | `0-15` | **Segment Limit** | `0-15` | Lower 16 bits |
| **2 - 3** | `0-15` | **Base Address** | `0-15` | Lower 16 bits |
| **4** | `0-7` | **Base Address** | `16-23` | Middle 8 bits |
| **5** | `0-7` | **Access Byte** | `0-7` | Type, privilege, and presence |
| **6** | `0-3` | **Segment Limit** | `16-19` | Upper 4 bits |
| **6** | `4-7` | **Flags** | `0-3` | Granularity and size flags |
| **7** | `0-7` | **Base Address** | `24-31` | Upper 8 bits |

### Access Byte (Byte 5)

| Bit(s) | Abbreviation | Flag Name | Description |
| :--- | :--- | :--- | :--- |
| **7** | `P` | **Present** | `1` (Valid segment), `0` (Invalid). |
| **5-6** | `DPL` | **Descriptor Privilege Level** | `0` (Kernel), `3` (User). |
| **4** | `S` | **Descriptor Type** | `1` (Code/Data), `0` (System). |
| **3** | `E` | **Executable** | `1` (Code), `0` (Data). |
| **2** | `DC` | **Direction / Conforming** | Code: `1` (Conforming). Data: `1` (Expands down). |
| **1** | `RW` | **Readable / Writable** | Code: `1` (Readable). Data: `1` (Writable). |
| **0** | `A` | **Accessed** | `1` (Accessed, set by CPU). |

### Flags (Byte 6, upper nibble)

| Bit(s) | Abbreviation | Flag Name | Description |
| :--- | :--- | :--- | :--- |
| **7** | `G` | **Granularity** | `1` (4 KiB units), `0` (Byte units). |
| **6** | `D/B` | **Default Bounds** | `1` (32-bit), `0` (16-bit). |
| **5** | `L` | **Long Mode** | `1` (64-bit segment). |
| **4** | `AVL` | **Available** | Reserved for OS use. |

## Statix Implementation

Statix uses a flat three-entry table:

| Descriptor | Base Address | Limit | Granularity | DPL | Access Byte | Note |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **[0] Null** | `0x0` | `0x0` | - | - | - | Required null entry |
| **[1] Code** | `0x0` | `0xFFFFF` | 1 (4 KiB) | 0 | `0x9A` | Executable and readable |
| **[2] Data** | `0x0` | `0xFFFFF` | 1 (4 KiB) | 0 | `0x92` | Writable data segment |

The code and data segments both cover the full 4 GiB linear address space, so
segmentation is effectively flat.

## References

- [Intel 64 and IA-32 Architectures Software Developer's Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [OSDev Wiki: Global Descriptor Table](https://wiki.osdev.org/Global_Descriptor_Table)
