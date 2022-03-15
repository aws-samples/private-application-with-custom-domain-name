document.getElementById("invoke").onclick = function() {hello()};

function hello() {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/api/hello", true);
    xhr.send();
    xhr.onload = function () {
        var data = JSON.parse(this.responseText);
        document.getElementById("result").innerHTML = data.message;
    }
}