FROM agents-base

# Official npm install (https://pi.dev). The curl installer does a managed
# install under ~/.pi/agent, which would land in the /root volume mount.
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

CMD pi
