// SPDX-License-Identifier: GPL-2.0
/*
 * ASoC Driver for the MNCAM audio board
 *
 * Author:  Martijn Braam <martijn@brixit.nl>
 * Based on the hifiberry driver from Joerg Schambacher <joerg@hifiberry.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/kernel.h>
#include <linux/clk.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/slab.h>
#include <linux/delay.h>
#include <linux/i2c.h>

#include <sound/core.h>
#include <sound/pcm.h>
#include <sound/pcm_params.h>
#include <sound/soc.h>
#include <sound/jack.h>
#include <sound/tlv.h>

//#include "../codecs/pcm186x.h"
#define PCM186X_PAGE_LEN		0x0100
#define PCM186X_PAGE_BASE(n)		(PCM186X_PAGE_LEN * n)
#define PCM186X_ADC1_INPUT_SEL_L	(PCM186X_PAGE_BASE(0) +   6)
#define PCM186X_ADC1_INPUT_SEL_R	(PCM186X_PAGE_BASE(0) +   7)
#define PCM186X_ADC_INPUT_SEL_MASK	GENMASK(5, 0)
#define PCM186X_MIC_BIAS_CTRL		(PCM186X_PAGE_BASE(3) +  21)


static const unsigned int pcm186x_adc_input_channel_sel_value[] = {
	0x00, 0x01, 0x10, 0x04, 0x08
};

static const char * const pcm186x_adcl_input_channel_sel_text[] = {
	"No Select",
	"XLR1 [SE]",					/* VINL1 */
	"XLR1 [DIFF]",
	"Line L",
	"Mic Internal",
};

static const char * const pcm186x_adcr_input_channel_sel_text[] = {
	"No Select",
	"XLR2 [SE]",					/* VINL1 */
	"XLR2 [DIFF]",
	"Line R",
	"Mic Internal",
};

static const struct soc_enum pcm186x_adc_input_channel_sel[] = {
	SOC_VALUE_ENUM_SINGLE(PCM186X_ADC1_INPUT_SEL_L, 0,
			      PCM186X_ADC_INPUT_SEL_MASK,
			      ARRAY_SIZE(pcm186x_adcl_input_channel_sel_text),
			      pcm186x_adcl_input_channel_sel_text,
			      pcm186x_adc_input_channel_sel_value),
	SOC_VALUE_ENUM_SINGLE(PCM186X_ADC1_INPUT_SEL_R, 0,
			      PCM186X_ADC_INPUT_SEL_MASK,
			      ARRAY_SIZE(pcm186x_adcr_input_channel_sel_text),
			      pcm186x_adcr_input_channel_sel_text,
			      pcm186x_adc_input_channel_sel_value),
};

static const unsigned int pcm186x_mic_bias_sel_value[] = {
	0x00, 0x01, 0x11
};

static const char * const pcm186x_mic_bias_sel_text[] = {
	"Mic Bias off",
	"Mic Bias on",
	"Mic Bias with Bypass Resistor"
};

static const struct soc_enum pcm186x_mic_bias_sel[] = {
	SOC_VALUE_ENUM_SINGLE(PCM186X_MIC_BIAS_CTRL, 0,
			      GENMASK(4, 0),
			      ARRAY_SIZE(pcm186x_mic_bias_sel_text),
			      pcm186x_mic_bias_sel_text,
			      pcm186x_mic_bias_sel_value),
};

static const struct snd_kcontrol_new pcm1863_snd_controls_card[] = {
	SOC_ENUM("ADC Left Input", pcm186x_adc_input_channel_sel[0]),
	SOC_ENUM("ADC Right Input", pcm186x_adc_input_channel_sel[1]),
	SOC_ENUM("ADC Mic Bias", pcm186x_mic_bias_sel),
};

static int pcm1863_add_controls(struct snd_soc_component *component)
{
	snd_soc_add_component_controls(component,
			pcm1863_snd_controls_card,
			ARRAY_SIZE(pcm1863_snd_controls_card));
	return 0;
}

static int snd_mncam_adc_init(struct snd_soc_pcm_runtime *rtd)
{
	struct snd_soc_dai *codec_dai = snd_soc_rtd_to_codec(rtd, 0);
	struct snd_soc_component *adc = codec_dai->component;
	int ret;

	ret = pcm1863_add_controls(adc);
	if (ret < 0)
		dev_warn(rtd->dev, "Failed to add pcm1863 controls: %d\n",
		ret);

	codec_dai->driver->capture.rates =
		SNDRV_PCM_RATE_44100 | SNDRV_PCM_RATE_48000 |
		SNDRV_PCM_RATE_88200 | SNDRV_PCM_RATE_96000 |
		SNDRV_PCM_RATE_176400 | SNDRV_PCM_RATE_192000;

	return 0;
}

static int snd_mncam_adc_hw_params(
	struct snd_pcm_substream *substream, struct snd_pcm_hw_params *params)
{
	int ret = 0;
	struct snd_soc_pcm_runtime *rtd = substream->private_data;
	int channels = params_channels(params);
	int width =  snd_pcm_format_width(params_format(params));

	/* Using powers of 2 allows for an integer clock divisor */
	width = width <= 16 ? 16 : 32;

	ret = snd_soc_dai_set_bclk_ratio(snd_soc_rtd_to_cpu(rtd, 0), channels * width);
	return ret;
}

/* machine stream operations */
static const struct snd_soc_ops snd_mncam_adc_ops = {
	.hw_params = snd_mncam_adc_hw_params,
};

SND_SOC_DAILINK_DEFS(hifi,
	DAILINK_COMP_ARRAY(COMP_CPU("bcm2708-i2s.0")),
	DAILINK_COMP_ARRAY(COMP_CODEC("pcm186x.1-004a", "pcm1863-aif")),
	DAILINK_COMP_ARRAY(COMP_PLATFORM("bcm2708-i2s.0")));

static struct snd_soc_dai_link snd_mncam_adc_dai[] = {
{
	.name		= "MNCAM ADC",
	.stream_name	= "MNCAM ADC HiFi",
	.dai_fmt	= SND_SOC_DAIFMT_I2S | SND_SOC_DAIFMT_NB_NF |
				SND_SOC_DAIFMT_CBS_CFS,
	.ops		= &snd_mncam_adc_ops,
	.init		= snd_mncam_adc_init,
	SND_SOC_DAILINK_REG(hifi),
},
};

/* audio machine driver */
static struct snd_soc_card snd_mncam_adc = {
	.name         = "snd_mncam_adc",
	.driver_name  = "MNCAMAudio",
	.owner        = THIS_MODULE,
	.dai_link     = snd_mncam_adc_dai,
	.num_links    = ARRAY_SIZE(snd_mncam_adc_dai),
};

static int snd_mncam_adc_probe(struct platform_device *pdev)
{
	int ret = 0, i = 0;
	struct snd_soc_card *card = &snd_mncam_adc;

	snd_mncam_adc.dev = &pdev->dev;
	if (pdev->dev.of_node) {
		struct device_node *i2s_node;
		struct snd_soc_dai_link *dai;

		dai = &snd_mncam_adc_dai[0];
		i2s_node = of_parse_phandle(pdev->dev.of_node,
			"i2s-controller", 0);
		if (i2s_node) {
			for (i = 0; i < card->num_links; i++) {
				dai->cpus->dai_name = NULL;
				dai->cpus->of_node = i2s_node;
				dai->platforms->name = NULL;
				dai->platforms->of_node = i2s_node;
			}
		}
	}
	ret = snd_soc_register_card(&snd_mncam_adc);
	if (ret && ret != -EPROBE_DEFER)
		dev_err(&pdev->dev,
			"snd_soc_register_card() failed: %d\n", ret);

	return ret;
}

static const struct of_device_id snd_mncam_adc_of_match[] = {
	{ .compatible = "fosdem,mncam-adc", },
	{},
};

MODULE_DEVICE_TABLE(of, snd_mncam_adc_of_match);

static struct platform_driver snd_mncam_adc_driver = {
	.driver = {
		.name   = "snd-mncam-adc",
		.owner  = THIS_MODULE,
		.of_match_table = snd_mncam_adc_of_match,
	},
	.probe          = snd_mncam_adc_probe,
};

module_platform_driver(snd_mncam_adc_driver);

MODULE_AUTHOR("Martijn Braam <martijn@brixit.nl.");
MODULE_DESCRIPTION("ASoC Driver for MNCAM ADC");
MODULE_LICENSE("GPL");
