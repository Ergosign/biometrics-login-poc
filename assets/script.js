function fillLoginForm(username, password) {
  document.getElementById("username").value = username;
  document.getElementById("password").value = password;
}

function validateForm() {
  const username = document.forms["loginForm"]["username"].value;
  const password = document.forms["loginForm"]["password"].value;
  const feedback = document.getElementById("feedback");
  if (username == "" || password == "") {
    feedback.innerHTML = "Please fill in all fields";
    feedback.style.color = "red";
    return false;
  }
  FlutterCallback.postMessage("authenticated");
  FlutterCallback.postMessage("loginData:" + username + "," + password);

  return true;
}

setTimeout(() => {
  const userElement = document.getElementById("username");
  const passwordElement = document.getElementById("password");

  userElement.addEventListener("focus", (event) => {
    if (userElement.value == "") {
      FlutterCallback.postMessage("focused");
    }
  });

  passwordElement.addEventListener("focus", (event) => {
    if (passwordElement.value == "") {
      FlutterCallback.postMessage("focused");
    }
  });
});
