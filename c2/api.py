import inspect
from functools import partial

from misirka.srv_wrapper.syncserver import MskSrv


class MisirkaAPI:
    def __init__(self, controls):
        self.controls = controls
        self.msk = MskSrv("/usr/local/bin/mkspipe", {
            "http": {"bind": ":8899"},
            "ws": {"enable": True},
            "mqtt": {"enable": True, "brokerurl": "tcp://127.0.0.1:1883", "prefix": "c2/"}
        })
        self.msk.open()
        self.msk.set_docs("ConfCam", descr="A Conference streaming camera")

        def handle_call(control, value):
            control.set(value, front=True)
            return "ok"

        for name in controls:
            control = controls[name]
            name = control.name
            if control.help is not None:
                desc = control.help
            else:
                desc = control.name
            desc += ".\n\n"
            if control.unit and control.min.value is not None:
                desc += f"Range: {control.min} {control.unit} - {control.max} {control.unit}\n"
            elif control.min.value is not None:
                desc += f"Range: {control.min} - {control.max}\n"
            if control.choices is not None:
                desc += "Choices: " + ", ".join(control.choices)
            examples = [control.value.value]
            if control.choices is not None:
                examples = control.choices
            self.msk.add_topic(name, desc, examples, True)
            self.msk.publish(name, control.value.value)

            if control.min.value is not None and control.max.value is not None:
                self.msk.add_topic(f"{name}-min", f"Minimum value for {name}", [control.min.value], True)
                self.msk.publish(f"{name}-min", control.min.value)
                self.msk.add_topic(f"{name}-max", f"Maximum value for {name}", [control.max.value], True)
                self.msk.publish(f"{name}-max", control.max.value)

            if not control.readonly:
                self.msk.add_call_kw(f"set-{name}", handler=partial(handle_call, control), descr=desc, examples=[
                    ({"value": control.value.value}, "ok")
                ])

        for name, help, cb in controls.actions:
            spec = inspect.getfullargspec(cb)
            if len(spec.args) == 0 or (len(spec.args) == 1 and spec.args[0] == 'self'):
                callback = lambda args: cb()
            else:
                callback = cb
            self.msk.add_call(name, callback, help, [({}, "ok")])
        self.run()

    def update(self):
        for name in self.controls:
            control = self.controls[name]
            name = control.name
            if control.value.once("misirka"):
                self.msk.publish(name, control.value.value)
            if control.min.value is not None and control.max.value is not None:
                if control.min.once("misirka"):
                    self.msk.publish(f"{name}-min", control.min.value)
                if control.max.once("misirka"):
                    self.msk.publish(f"{name}-max", control.max.value)

    def run(self):
        self.msk.serve()
