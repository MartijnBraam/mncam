import math


class Log10Mapper:
    def from_back(self, val):
        return 10 * math.log10(val)

    def from_front(self, val):
        return 10 ** (val / 10.0)


class StateValue:
    def __init__(self, initial=None):
        self.value = None
        self.last_value = None
        self._changed = {None: False}

        if initial is not None:
            self.value = initial
            self._changed[None] = True

    def set(self, value):
        self.value = value
        if self.value != self.last_value:
            self.last_value = self.value
            self.force_state(True)

    def force_state(self, state):
        for k in self._changed:
            self._changed[k] = state

    def toggle(self, strval=None):
        if strval is not None:
            if self.value != strval:
                self.set(strval)
            else:
                self.set("")
            return
        self.set(not self.value)

    def once(self, selector=None):
        if selector not in self._changed:
            self._changed[selector] = False
            return True
        changed = self._changed[selector]
        self._changed[selector] = False
        return changed

    def __str__(self):
        return str(self.value)


class StateControl:
    def __init__(self, name, value=None, minv=None, maxv=None, readonly=False, unit=None, mapper=None, help=None,
                 choices=None):
        self.mapper = mapper

        if mapper is not None:
            value = mapper.from_back(value)
            if minv is not None:
                minv = mapper.from_back(minv)
            if maxv is not None:
                maxv = mapper.from_back(maxv)

        self.name = name
        self.unit = unit
        self.readonly = readonly
        self.value = StateValue(value)
        self.min = StateValue(minv)
        self.max = StateValue(maxv)

        self.handler = None
        self.help = help
        self.choices = choices

    def set_handler(self, fun):
        self.handler = fun

    def set(self, val, front=True):
        if self.mapper is not None:
            if front:
                val = self.mapper.from_front(val)
            else:
                val = self.mapper.from_back(val)

        if not front:
            self.value.set(val)

        if self.handler is not None and front:
            self.handler(val)

    def __repr__(self):
        return f'<StateControl {self.name}={self.value} {self.unit} [{self.min} - {self.max}]>'

    def __str__(self):
        return str(self.value)

    def __bool__(self):
        return bool(self.value.value)


class ControlCollection(dict):
    def __init__(self):
        super().__init__()
        self.actions = []

    def add(self, control: StateControl, key=None):
        if key is None:
            key = control.name
        self[key] = control

    def add_action(self, name, help, callback):
        self.actions.append((name, help, callback))

    def __getattr__(self, name) -> StateControl:
        return self[name]
