@_default: help

# Lists all available tasks
help:
  just --list

# Sets up the base Jupyter Lab environment (asdf install + base venv) or a specific project if name is provided
setup name='':
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -z "{{name}}" ]; then
    just asdf-install
    just base-install
    exit 0
  fi
  just asdf-install
  ORIGINAL_NAME="{{name}}"
  # Strip a leading "name=" if provided (e.g., just setup name=foo)
  STRIPPED_NAME="${ORIGINAL_NAME#name=}"
  # If strip results in empty, fall back to original
  if [ -z "$STRIPPED_NAME" ]; then
    STRIPPED_NAME="$ORIGINAL_NAME"
  fi
  # Sanitize for kernel/dir: allow only a-zA-Z0-9._-; replace others with '-'
  SANITIZED_NAME=$(printf "%s" "$STRIPPED_NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
  if [ -z "$SANITIZED_NAME" ]; then
    echo "Error: Invalid project name '$ORIGINAL_NAME' after sanitization."
    echo "Use only letters, numbers, hyphen (-), underscore (_), and period (.)"
    exit 1
  fi
  PROJECT_DIR="notebooks/$SANITIZED_NAME"
  if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
    if [ ! -f "$PROJECT_DIR/requirements.txt" ]; then
      echo "# Requirements for $STRIPPED_NAME" > "$PROJECT_DIR/requirements.txt"
      echo "# Add your dependencies below" >> "$PROJECT_DIR/requirements.txt"
    fi
  fi
  cd "$PROJECT_DIR"
  if [ ! -d ".venv" ]; then
    uv venv --python=3.12
  fi
  source .venv/bin/activate
  uv pip install ipykernel
  if [ -s requirements.txt ] && [ "$(grep -v '^#' requirements.txt | grep -v '^[[:space:]]*$')" ]; then
    uv pip install -r requirements.txt
  fi
  python -m ipykernel install --user --name="$SANITIZED_NAME" --display-name="Python ($STRIPPED_NAME)"
  echo "✓ Project $STRIPPED_NAME ready at $PROJECT_DIR (kernel: $SANITIZED_NAME)"
  echo "✓ Kernel 'Python ($STRIPPED_NAME)' registered"

# Install asdf requirements
asdf-install:
  asdf install

# Create base venv and install latest Jupyter Lab
base-install:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ ! -d ".venv" ]; then
    uv venv --python=3.12
  fi
  source .venv/bin/activate
  uv pip install --upgrade jupyterlab notebook ipykernel ipywidgets
  echo "✓ Base environment ready with JupyterLab $(uv pip show jupyterlab | grep Version | cut -d' ' -f2)"

# Create a new project with its own venv and kernel
new-project name:
  #!/usr/bin/env bash
  set -euo pipefail
  # Sanitize name
  SANITIZED_NAME=$(printf "%s" "{{name}}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
  if [ -z "$SANITIZED_NAME" ]; then
    echo "Error: Invalid project name '{{name}}' after sanitization."
    echo "Use only letters, numbers, hyphen (-), underscore (_), and period (.)"
    exit 1
  fi
  PROJECT_DIR="notebooks/$SANITIZED_NAME"
  if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Project $SANITIZED_NAME already exists at $PROJECT_DIR"
    exit 1
  fi
  mkdir -p "$PROJECT_DIR"
  # Create minimal requirements.txt
  echo "# Core data science stack (uncomment as needed)" > "$PROJECT_DIR/requirements.txt"
  echo "# pandas>=2.2.0" >> "$PROJECT_DIR/requirements.txt"
  echo "# numpy>=1.26.0" >> "$PROJECT_DIR/requirements.txt"
  echo "# matplotlib>=3.8.0" >> "$PROJECT_DIR/requirements.txt"
  echo "# scikit-learn>=1.4.0" >> "$PROJECT_DIR/requirements.txt"
  echo "" >> "$PROJECT_DIR/requirements.txt"
  echo "# Deep learning (uncomment as needed)" >> "$PROJECT_DIR/requirements.txt"
  echo "# torch>=2.1.0" >> "$PROJECT_DIR/requirements.txt"
  echo "# transformers>=4.36.0" >> "$PROJECT_DIR/requirements.txt"
  echo "" >> "$PROJECT_DIR/requirements.txt"
  echo "# Add your project-specific dependencies below" >> "$PROJECT_DIR/requirements.txt"
  cd "$PROJECT_DIR"
  uv venv --python=3.12
  source .venv/bin/activate
  uv pip install ipykernel
  python -m ipykernel install --user --name="$SANITIZED_NAME" --display-name="Python ({{name}})"
  echo "✓ Project {{name}} created at $PROJECT_DIR"
  echo "✓ Kernel 'Python ({{name}})' registered as: $SANITIZED_NAME"
  echo ""
  echo "Next steps:"
  echo "  1. Edit $PROJECT_DIR/requirements.txt to add dependencies"
  echo "  2. Run: just install-deps {{name}}"
  echo "  3. Run: just lab"

# Install/update dependencies for a project
install-deps name:
  #!/usr/bin/env bash
  set -euo pipefail
  SANITIZED_NAME=$(printf "%s" "{{name}}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
  PROJECT_DIR="notebooks/$SANITIZED_NAME"
  if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project not found at $PROJECT_DIR"
    echo "Available projects:"
    just list-projects
    exit 1
  fi
  if [ ! -f "$PROJECT_DIR/requirements.txt" ]; then
    echo "Error: requirements.txt not found in $PROJECT_DIR"
    exit 1
  fi
  if [ ! -d "$PROJECT_DIR/.venv" ]; then
    echo "Error: .venv not found in $PROJECT_DIR. Run 'just new-project {{name}}' first."
    exit 1
  fi
  cd "$PROJECT_DIR"
  source .venv/bin/activate
  uv pip install -r requirements.txt
  echo "✓ Dependencies installed for {{name}}"

# Clone an existing project as a template for a new one
clone-project source target:
  #!/usr/bin/env bash
  set -euo pipefail
  SOURCE_SANITIZED=$(printf "%s" "{{source}}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
  TARGET_SANITIZED=$(printf "%s" "{{target}}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
  SOURCE_DIR="notebooks/$SOURCE_SANITIZED"
  TARGET_DIR="notebooks/$TARGET_SANITIZED"
  if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source project not found at $SOURCE_DIR"
    exit 1
  fi
  if [ -d "$TARGET_DIR" ]; then
    echo "Error: Target project already exists at $TARGET_DIR"
    exit 1
  fi
  mkdir -p "$TARGET_DIR"
  if [ -f "$SOURCE_DIR/requirements.txt" ]; then
    cp "$SOURCE_DIR/requirements.txt" "$TARGET_DIR/requirements.txt"
  fi
  cd "$TARGET_DIR"
  uv venv --python=3.12
  source .venv/bin/activate
  uv pip install ipykernel
  if [ -f requirements.txt ]; then
    uv pip install -r requirements.txt
  fi
  python -m ipykernel install --user --name="$TARGET_SANITIZED" --display-name="Python ({{target}})"
  echo "✓ Cloned {{source}} → {{target}}"
  echo "✓ Kernel 'Python ({{target}})' registered"

# List all projects in notebooks/
list-projects:
  #!/usr/bin/env bash
  if [ ! -d "notebooks" ] || [ -z "$(ls -A notebooks 2>/dev/null)" ]; then
    echo "No projects found. Create one with: just new-project <name>"
    exit 0
  fi
  echo "Available projects:"
  for dir in notebooks/*/; do
    if [ -d "$dir" ]; then
      name=$(basename "$dir")
      if [ -d "$dir/.venv" ]; then
        echo "  ✓ $name"
      else
        echo "  ✗ $name (no venv)"
      fi
    fi
  done

# Start Jupyter Lab server from base environment
lab:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ ! -d ".venv" ]; then
    echo "Base environment not found. Run 'just setup' first."
    exit 1
  fi
  source .venv/bin/activate
  jupyter lab

# Alternative: start lab (same as lab)
start-lab:
  just lab

# Upgrade JupyterLab to latest version in base environment
upgrade-lab:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ ! -d ".venv" ]; then
    echo "Base environment not found. Run 'just setup' first."
    exit 1
  fi
  source .venv/bin/activate
  uv pip install --upgrade jupyterlab notebook ipykernel ipywidgets
  echo "✓ JupyterLab upgraded to $(uv pip show jupyterlab | grep Version | cut -d' ' -f2)"

# List all registered Jupyter kernels
list-kernels:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -d ".venv" ]; then
    source .venv/bin/activate
  fi
  jupyter kernelspec list

# Remove a project's kernel (but not the project files)
remove-kernel name:
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -d ".venv" ]; then
    source .venv/bin/activate
  fi
  SANITIZED_NAME=$(printf "%s" "{{name}}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
  jupyter kernelspec uninstall "$SANITIZED_NAME" -y
  echo "✓ Kernel $SANITIZED_NAME removed"

# Delete a project completely (files + kernel)
delete-project name:
  #!/usr/bin/env bash
  set -euo pipefail
  SANITIZED_NAME=$(printf "%s" "{{name}}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9._-]+/-/g' | sed -E 's/^-+|-+$//g')
  PROJECT_DIR="notebooks/$SANITIZED_NAME"
  if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project not found at $PROJECT_DIR"
    exit 1
  fi
  echo "⚠️  This will delete $PROJECT_DIR and its kernel"
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
  fi
  # Remove kernel first
  if [ -f "../.venv/bin/activate" ]; then
    source ../.venv/bin/activate
    jupyter kernelspec uninstall "$SANITIZED_NAME" -y 2>/dev/null || echo "Kernel not found, skipping"
  fi
  # Remove project directory
  rm -rf "$PROJECT_DIR"
  echo "✓ Project $SANITIZED_NAME deleted"

# Clean up cache and temporary files across all projects
clean:
  #!/usr/bin/env bash
  echo "Cleaning cache and temporary files..."
  rm -rf .ipynb_checkpoints 2>/dev/null || true
  rm -rf __pycache__ 2>/dev/null || true
  find . -type d -name ".ipynb_checkpoints" -exec rm -rf {} + 2>/dev/null || true
  find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
  find . -type f -name "*.pyc" -delete 2>/dev/null || true
  echo "✓ Cleaned"

# Remove base venv completely (keeps project venvs)
clean-base-venv:
  rm -rf .venv
  echo "✓ Base venv removed. Run 'just setup' to recreate."

# Remove all project venvs (keeps base venv and project files)
clean-project-venvs:
  #!/usr/bin/env bash
  echo "Removing all project venvs..."
  find notebooks -type d -name ".venv" -exec rm -rf {} + 2>/dev/null || true
  echo "✓ Project venvs removed. Run 'just setup <name>' to recreate."

# Show system info
info:
  #!/usr/bin/env bash
  echo "=== ML Labs Environment ==="
  echo ""
  echo "Tool versions:"
  python --version 2>/dev/null || echo "  Python: not found"
  uv --version 2>/dev/null || echo "  uv: not found"
  just --version 2>/dev/null || echo "  just: not found"
  echo ""
  if [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "JupyterLab: $(uv pip show jupyterlab 2>/dev/null | grep Version | cut -d' ' -f2 || echo 'not installed')"
  else
    echo "JupyterLab: base environment not setup"
  fi
  echo ""
  echo "Projects: $(find notebooks -maxdepth 1 -type d 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')"
  echo "Kernels: $(jupyter kernelspec list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')"
