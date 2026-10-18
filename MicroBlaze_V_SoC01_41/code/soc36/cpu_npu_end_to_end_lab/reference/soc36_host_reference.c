#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static int32_t round_away_pow2(
    int64_t value,
    unsigned shift
)
{
    uint64_t magnitude;
    uint64_t rounded;

    if (shift == 0U) {
        return (int32_t)value;
    }

    magnitude =
        (value < 0) ?
        (uint64_t)(-value) :
        (uint64_t)value;

    rounded =
        (
            magnitude +
            ((uint64_t)1U << (shift - 1U))
        ) >> shift;

    return
        (value < 0) ?
        -(int32_t)rounded :
        (int32_t)rounded;
}

static int8_t requant(
    int32_t acc,
    int32_t bias,
    int16_t mult,
    unsigned shift,
    int16_t zp
)
{
    int64_t product =
        ((int64_t)acc + bias) * mult;

    int32_t value =
        round_away_pow2(
            product,
            shift
        ) + zp;

    if (value > 127) {
        value = 127;
    }

    if (value < -128) {
        value = -128;
    }

    return (int8_t)value;
}

static uint32_t pack4(
    const int8_t *values
)
{
    uint32_t packed = 0U;

    for (unsigned i = 0U; i < 4U; ++i) {
        packed |=
            ((uint32_t)(uint8_t)values[i]) <<
            (i * 8U);
    }

    return packed;
}

static int run_case(
    const int32_t input[8],
    uint32_t expected0,
    uint32_t expected1
)
{
    int8_t q0[4];
    int8_t q1[4];

    for (unsigned i = 0U; i < 4U; ++i) {
        q0[i] = requant(
            input[i],
            0,
            1,
            1U,
            0
        );

        q1[i] = requant(
            input[i + 4U],
            4,
            3,
            1U,
            -3
        );
    }

    const uint32_t out0 = pack4(q0);
    const uint32_t out1 = pack4(q1);

    printf(
        "out0=0x%08X out1=0x%08X\n",
        out0,
        out1
    );

    return
        (out0 == expected0) &&
        (out1 == expected1);
}

int main(void)
{
    const int32_t job0[8] = {
        16, 32, 48, 64,
        32, 64, 96, 128
    };

    const int32_t job1[8] = {
        2, 4, 6, 8,
        4, 8, 12, 16
    };

    if (!run_case(
        job0,
        0x20181008U,
        0x7F7F6333U
    )) {
        return EXIT_FAILURE;
    }

    if (!run_case(
        job1,
        0x04030201U,
        0x1B150F09U
    )) {
        return EXIT_FAILURE;
    }

    puts("SOC36 HOST CPU REFERENCE: PASS");
    return EXIT_SUCCESS;
}
