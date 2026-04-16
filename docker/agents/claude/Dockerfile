FROM agents-base

ENV BASH_MAX_OUTPUT_LENGTH=5000 \
    CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1 \
    CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1 \
    CLAUDE_CODE_DISABLE_MOUSE=1 \
    DISABLE_NON_ESSENTIAL_MODEL_CALLS=1 \
    DISABLE_TELEMETRY=1 \
    IS_SANDBOX=1

RUN curl -fsSL https://claude.ai/install.sh | bash && \
    cp -L /root/.local/bin/claude /usr/local/bin/claude

CMD claude
