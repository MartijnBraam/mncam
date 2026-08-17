from functools import partial

from misirka.srv_wrapper.syncserver import MskSrv


class MisirkaAPI:
    def __init__(self, controls):
        self.controls = controls
        self.msk = MskSrv("/usr/local/bin/mkspipe", {
            "http": {"bind": ":8899"},
            "mqtt": {"enable": True, "brokerurl": "tcp://127.0.0.1:1883", "prefix": "c2/"}
        })
        self.msk.open()
        self.msk.set_docs("ConfCam", descr="A Conference streaming camera")

        def handle_call(control, value):
            print("MISIRKA")
            control.set(value, front=True)
            return "ok!"

        for name in controls:
            control = controls[name]
            if control.help is not None:
                desc = control.help
            else:
                desc = control.name
            desc += ".\n\n"
            if control.unit:
                desc += f"Range: {control.min} {control.unit} - {control.max} {control.unit}\n"
            else:
                desc += f"Range: {control.min} - {control.max}\n"
            self.msk.add_topic(name, desc, [control.value.value], True)
            self.msk.publish(name, control.value.value)
            self.msk.add_call_kw(f"set-{name}", handler=partial(handle_call, control), descr=desc, examples=[
                ({"value": control.value.value}, "ok")
            ])

        self.run()

    def update(self):
        for name in self.controls:
            control = self.controls[name]
            if control.value.once("misirka"):
                self.msk.publish(name, control.value.value)

    def run(self):
        self.msk.serve()