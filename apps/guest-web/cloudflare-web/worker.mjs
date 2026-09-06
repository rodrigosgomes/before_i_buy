import openNextWorker from "../.open-next/worker.js";

const invitePath = /\/invite\/[A-Za-z0-9_-]{43}\/?$/;
const neutralInvitePath = "/invite/___________________________________________";

const worker = {
  fetch(request, env, context) {
    const url = new URL(request.url);
    if (!invitePath.test(url.pathname)) {
      return openNextWorker.fetch(request, env, context);
    }
    url.pathname = url.pathname.replace(invitePath, neutralInvitePath);
    return openNextWorker.fetch(new Request(url, request), env, context);
  },
};

export default worker;
