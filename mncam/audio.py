import alsaaudio

from mncam.config import Config


class AudioManager:
    def __init__(self, config: Config):
        self._config = config

        cards = alsaaudio.cards()
        input_idx = cards.index(config.audio.input_device)
        output_idx = cards.index(config.audio.output_device)

        self._pga_left = alsaaudio.Mixer(cardindex=input_idx, control='PGA Gain Left')
        self._pga_right = alsaaudio.Mixer(cardindex=input_idx, control='PGA Gain Right')

        self.set_gain('L', config.audio.left_gain)
        self.set_gain('R', config.audio.right_gain)

    def set_gain(self, channel, gain):
        halfdb = int(gain * 2 + 0.5) / 2
        item = f'{halfdb:.1f}dB'
        cur, items = self._pga_left.getenum()
        index = items.index(item)
        if channel == 'L':
            self._pga_left.setenum(index)
            self._config.audio.left_gain = int(gain)
        else:
            self._pga_right.setenum(index)
            self._config.audio.right_gain = int(gain)
        self._config.save_config()

    def get_min_gain(self):
        return -12

    def get_max_gain(self):
        return 40

    def set_routing(self, channel, source):
        pass
