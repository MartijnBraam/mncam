function ajax(path, callback, method = "GET", data = undefined) {
    let ri = {
        method: method,
        headers: {
            'Content-type': 'application/json'
        },
    };
    if (data !== undefined) {
        ri['body'] = JSON.stringify(data);
    }
    fetch("/control/api/v1" + path, ri)
        .then((response) => {
            if (!response.ok) {
                thorw
                Error(response.statusText);
            }
            return response;
        })
        .then((response) => response.json())
        .then((data) => {
            if (callback !== null && callback !== undefined) {
                callback(data)
            }
        })
        .catch((error) => {
            console.error(error);
        })
}

function Binding(state, key) {
    const _this = this;
    this.value = state[key];
    if (this.value === undefined) {
        this.value = {};
    }
    this.bindings = [];

    this.valueGetter = function () {
        return _this.value;
    }
    this.valueSetter = function (val) {
        console.log("Set value to ", val);
        _this.value = val;
        for (let i = 0; i < _this.bindings.length; i++) {
            _this.bindings[i](val);
        }
    }
    this.onChange = function (callback) {
        this.bindings.push(callback);
        return _this;
    }

    Object.defineProperty(state, key, {
        get: this.valueGetter,
        set: this.valueSetter,
    });

    state[key] = this.value;
}

let properties = {};

document.addEventListener("DOMContentLoaded", function () {
    ajax("/system", function (data) {
        window.mode.innerHTML = "<span>" + data.videoFormat.name + "</span>";
        window.shutter.min = data.videoFormat.frameRate;
    });
    const ws = new WebSocket("/control/api/v1/event/websocket");

    new Binding(properties, "/video/whiteBalance").onChange(function (data) {
        window.whitebalance.value = data.whiteBalance;
        window.whitebalanceLabel.innerText = data.whiteBalance + "k";
    })
    window.whitebalance.oninput = function (el) {
        const val = el.value;
        ajax("/video/whiteBalance")
    }

    window.gain.oninput = function (event) {
        let data = {"gain": parseInt(event.target.value, 10)}
        ajax("/video/gain", null, "PUT", data);
    }
    new Binding(properties, "/video/gain").onChange(function (data) {
        window.gain.value = data.gain;
        window.gainLabel.innerText = Math.round(data.gain) + " dB";
    })

    window.shutter.oninput = function (event) {
        let data = {"shutterSpeed": parseInt(event.target.value, 10)}
        ajax("/video/shutter", null, "PUT", data);
    }
    new Binding(properties, "/video/shutter").onChange(function (data) {
        window.shutter.value = data.shutterSpeed;
        window.shutterLabel.innerText = "1/" + data.shutterSpeed;
    })

    window.ae.oninput = function (event) {
        let data = {"mode": "Off"}
        if (event.target.checked) {
            data["mode"] = "Continuous";
        }
        ajax("/video/autoExposure", null, "PUT", data);
    }
    window.ec.oninput = function (event) {
        let data = {"compensation": event.target.value / 3}
        ajax("/video/autoExposure", null, "PUT", data);
    }
    new Binding(properties, "/video/autoExposure").onChange(function (data) {
        window.ae.checked = data.mode === "Continuous";

        window.gain.disabled = window.ae.checked;
        window.shutter.disabled = window.ae.checked;
        window.ec.disabled = !window.ae.checked;

        window.ec.value = data.compensation * 3;
        const ec = (Math.round(data.compensation * 3) / 3).toFixed(1);
        window.ecLabel.innerText = ec + " EV";
    })

    window.tally.oninput = function (event) {
        let data = {"status": event.target.value}
        ajax("/camera/tallyStatus", null, "PUT", data);
    }
    new Binding(properties, "/camera/tallyStatus").onChange(function (data) {
        window.tally.tally.value = data.status;
        let color = '#262626';
        switch (data.status) {
            case "Program":
                color = "#F00";
                break;
            case "Preview":
                color = "#0F0";
                break;
        }
        window.header.style.backgroundImage = 'linear-gradient(180deg, ' + color + ' 0%, #181818 100%)';
    })


    ws.onopen = (event) => {
        console.log("Event socket opened");
        ws.send(JSON.stringify({type: "request", data: {action: "listProperties"}}));
    }
    ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        console.log("Message", data);
        if (data.type === "event") {
            if (data.data.action === "propertyValueChanged") {
                let old = properties[data.data.property];
                if (old === undefined) {
                    return;
                }
                Object.assign(old, data.data.value);
                properties[data.data.property] = old;
            }
        } else if (data.type === "response") {
            if (data.data.action === "listProperties") {
                for (let i = 0; i < data.data.properties.length; i++) {
                    ws.send(JSON.stringify({
                        type: "request",
                        data: {action: "subscribe", properties: [data.data.properties[i]]}
                    }));
                }
            }
        }
    }
});