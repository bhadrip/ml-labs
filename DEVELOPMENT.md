# ML Labs Development Guide

A justfile-based workflow for isolated ML experiments with per-project Jupyter kernels.

## Architecture

```
ml-labs/
├── .tool-versions        # Python 3.12.3, uv 0.9.3, just 1.35.0
├── .gitignore           # Comprehensive Python/Jupyter ignore rules
├── justfile             # Task automation (18 commands)
├── notebooks/           # Your experiments go here
│   ├── experiment-1/
│   │   ├── .venv/      # Isolated Python environment
│   │   ├── requirements.txt
│   │   └── *.ipynb
│   └── experiment-2/
│       ├── .venv/
│       ├── requirements.txt
│       └── *.ipynb
└── .venv/               # Base environment (JupyterLab only)
```

## Philosophy: Per-Folder Kernels

Each experiment gets its own isolated kernel for:

- **Dependency Isolation** - Experiment A uses `torch==2.0` while B needs `torch==1.13` - no conflicts
- **Reproducibility** - Each folder's `requirements.txt` is self-contained; share/archive individual experiments cleanly
- **Freedom to Break Things** - Install experimental packages in one kernel without risking other work
- **Memory Management** - Restart a kernel without affecting others (important for memory-heavy ML work)
- **Time Travel** - Keep old experiments frozen in time with their exact dependency versions

## Quick Start

### Initial Setup

```bash
# Install dependencies and create base JupyterLab environment
just setup

# Verify installation
just info
```

### Create Your First Experiment

```bash
# Create a new isolated project
just new-project modeling-what-makes-a-model-learn
```

This creates:
- `notebooks/modeling-what-makes-a-model-learn/` folder
- Isolated `.venv` with Python 3.12
- Dedicated Jupyter kernel registered as `modeling-what-makes-a-model-learn`
- `requirements.txt` template with common ML packages commented out

### Add Dependencies

```bash
# 1. Edit the requirements.txt file
vim notebooks/modeling-what-makes-a-model-learn/requirements.txt

# Uncomment or add packages, e.g.:
# pandas>=2.2.0
# numpy>=1.26.0
# matplotlib>=3.8.0
# scikit-learn>=1.4.0

# 2. Install dependencies
just install-deps modeling-what-makes-a-model-learn
```

### Start JupyterLab

```bash
# Launch JupyterLab with all kernels available
just lab
```

In JupyterLab:
1. Create a new notebook
2. Select kernel: **"Python (modeling-what-makes-a-model-learn)"**
3. Start experimenting!

## Complete Workflow Example

```bash
# 1. Create experiment for agent framework comparison
just new-project agents-openai-vs-langgraph

# 2. Edit requirements.txt to add agent dependencies
cat >> notebooks/agents-openai-vs-langgraph/requirements.txt << 'EOF'
openai>=1.0.0
langgraph>=0.1.0
langchain-core>=0.3.0
langchain-openai>=0.2.0
EOF

# 3. Install dependencies
just install-deps agents-openai-vs-langgraph

# 4. Launch JupyterLab
just lab

# 5. In JupyterLab: Select kernel "Python (agents-openai-vs-langgraph)"
# 6. Create notebooks and experiment
```

## Command Reference

### Project Management

| Command | Description | Example |
|---------|-------------|---------|
| `just new-project <name>` | Create isolated experiment folder + kernel | `just new-project rag-evaluation` |
| `just list-projects` | List all projects and their status | `just list-projects` |
| `just clone-project <src> <dst>` | Clone project setup (copies requirements.txt) | `just clone-project agents-base agents-v2` |
| `just delete-project <name>` | Remove project folder and kernel (interactive) | `just delete-project old-experiment` |

### Dependency Management

| Command | Description | Example |
|---------|-------------|---------|
| `just install-deps <name>` | Install/update project dependencies from requirements.txt | `just install-deps my-project` |
| `just setup` | Create base JupyterLab environment | `just setup` |
| `just setup <name>` | Create/setup a specific project | `just setup new-experiment` |

### JupyterLab

| Command | Description |
|---------|-------------|
| `just lab` | Start JupyterLab server (alias: `just start-lab`) |
| `just upgrade-lab` | Upgrade JupyterLab to latest version in base environment |

### Kernel Management

| Command | Description | Example |
|---------|-------------|---------|
| `just list-kernels` | List all registered Jupyter kernels | `just list-kernels` |
| `just remove-kernel <name>` | Remove kernel but keep project files | `just remove-kernel old-experiment` |

### Maintenance

| Command | Description |
|---------|-------------|
| `just clean` | Remove cache and temporary files (.ipynb_checkpoints, __pycache__, *.pyc) |
| `just clean-base-venv` | Remove base venv completely (keeps project venvs) |
| `just clean-project-venvs` | Remove all project venvs (keeps base venv and files) |
| `just info` | Show environment info (versions, project count, kernel count) |

### System

| Command | Description |
|---------|-------------|
| `just help` | List all available commands (alias: `just --list`) |
| `just asdf-install` | Install asdf tool versions from .tool-versions |
| `just base-install` | Create base venv and install JupyterLab |

## Common Workflows

### Cloning an Existing Setup

When you want to reuse dependency configurations:

```bash
# Clone project A's setup for project B
just clone-project modeling-regression-basics modeling-regularization
# This copies requirements.txt and creates a new kernel
```

### Updating Dependencies

```bash
# Edit requirements.txt
vim notebooks/my-project/requirements.txt

# Reinstall
just install-deps my-project
```

### Sharing an Experiment

Each experiment is self-contained:

```bash
# Archive a single experiment
tar -czf experiment.tar.gz notebooks/modeling-what-makes-a-model-learn/

# Share with collaborator
# They can extract and run: just setup modeling-what-makes-a-model-learn
```

### Cleaning Up Old Experiments

```bash
# Remove just the kernel (keep files for reference)
just remove-kernel old-experiment

# Remove everything (interactive confirmation)
just delete-project old-experiment

# Or manually
rm -rf notebooks/old-experiment
just remove-kernel old-experiment
```

### Troubleshooting

**Problem: Kernel not showing up in JupyterLab**

```bash
# Verify kernel is registered
just list-kernels

# Re-register if needed
just setup <project-name>
```

**Problem: Dependency conflicts**

```bash
# Each project has its own venv, so conflicts shouldn't happen
# If they do, check you're using the right kernel:
just list-kernels

# Recreate project if needed
just delete-project <name>
just new-project <name>
```

**Problem: Out of disk space**

```bash
# Check project count
just info

# Clean up unused projects
just delete-project <unused-project-1>
just delete-project <unused-project-2>

# Or remove all project venvs (keeps files)
just clean-project-venvs
```

## Project Organization Tips

### Naming Conventions

Use descriptive, lowercase names with hyphens:

```bash
# Good
just new-project modeling-bias-variance-tradeoff
just new-project agents-langgraph-memory-systems
just new-project rag-evaluation-metrics

# Avoid
just new-project MyProject  # Gets lowercased anyway
just new-project test1      # Not descriptive
```

### Obsidian-Style Organization

Since you want "Obsidian with dynamic runtime components," consider:

**Option 1: Markdown README per project**

```bash
# In each project folder, create a README.md with YAML frontmatter
cat > notebooks/modeling-bias-variance/README.md << 'EOF'
---
section: Modeling & Statistical Foundations
type: Experiment
status: In Progress
tags: [regression, overfitting, visualization]
---

# What Data Wants: The Bias-Variance Balancing Act

## Central Question
Why can adding noise sometimes improve generalization?

## Approach
- Generate synthetic polynomial data
- Train models of varying complexity
- Plot training vs test error curves
- Visualize bias-variance decomposition

## Key Findings
TBD
EOF
```

**Option 2: Prefix-based organization**

```bash
just new-project 01-modeling-gradient-descent
just new-project 02-modeling-regularization
just new-project 03-dl-transformer-attention
just new-project 04-agents-openai-vs-langgraph
```

**Option 3: Section-based tagging script** (future enhancement)

```bash
# Could add a command like:
just tag-project modeling-bias-variance "Modeling & Statistical Foundations"
# This would create symlinks or maintain a tags.json index
```

## Requirements.txt Templates

### Minimal Data Science

```
pandas>=2.2.0
numpy>=1.26.0
matplotlib>=3.8.0
seaborn>=0.13.0
```

### Classical ML

```
pandas>=2.2.0
numpy>=1.26.0
matplotlib>=3.8.0
scikit-learn>=1.4.0
scipy>=1.12.0
```

### Deep Learning (PyTorch)

```
torch>=2.1.0
torchvision>=0.16.0
tensorboard>=2.15.0
pandas>=2.2.0
numpy>=1.26.0
matplotlib>=3.8.0
```

### NLP & Transformers

```
transformers>=4.36.0
datasets>=2.16.0
tokenizers>=0.15.0
sentencepiece>=0.1.99
torch>=2.1.0
```

### RAG & Agents

```
openai>=1.0.0
langgraph>=0.1.0
langchain-core>=0.3.0
langchain-openai>=0.2.0
chromadb>=0.4.0
sentence-transformers>=2.3.0
```

### MLOps & Monitoring

```
mlflow>=2.9.0
evidently>=0.4.0
prometheus-client>=0.19.0
fastapi>=0.108.0
uvicorn>=0.25.0
```

## Environment Info

Current setup:
- **Python**: 3.12.3
- **uv**: 0.9.3 (fast package installer)
- **just**: 1.35.0 (task runner)
- **JupyterLab**: 4.4.10 (latest)

View anytime with:
```bash
just info
```

## Advanced: Extending the Justfile

The justfile is extensible. Common additions:

### Add a backup command

```justfile
# Backup all notebooks to timestamped archive
backup:
  #!/usr/bin/env bash
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  tar -czf "backups/ml-labs-$TIMESTAMP.tar.gz" notebooks/
  echo "✓ Backed up to backups/ml-labs-$TIMESTAMP.tar.gz"
```

### Add a format command

```justfile
# Format all Python code in notebooks
format:
  #!/usr/bin/env bash
  source .venv/bin/activate
  pip install black
  black notebooks/
```

### Add a test command

```justfile
# Run tests for a project
test name:
  #!/usr/bin/env bash
  PROJECT_DIR="notebooks/{{name}}"
  cd "$PROJECT_DIR"
  source .venv/bin/activate
  pytest tests/
```

## FAQ

**Q: Can I use Node.js projects?**
A: Currently Python-only. For Node.js, consider adding `just new-node-project <name>` that creates a package.json instead of requirements.txt.

**Q: Can I share the base venv across projects?**
A: No, that defeats the purpose of isolation. Each project needs its own venv. Only JupyterLab itself lives in the base venv.

**Q: How much disk space per project?**
A: ~200-500MB for minimal setups, ~1-2GB for deep learning with PyTorch/TensorFlow.

**Q: Can I use this with Docker?**
A: Yes, but you'd typically run JupyterLab inside Docker. The justfile workflow works great for local development.

**Q: What if I want to use Python 3.11 for one project?**
A: Edit the `uv venv --python=3.12` line in justfile's `new-project` command to use a variable, or manually create that project's venv with Python 3.11.

## Next Steps

1. Create your first experiment: `just new-project <name>`
2. Review the [README.md](README.md) for project context
3. Start exploring the 40+ experiment ideas from your planning doc
4. Consider adding markdown READMEs to each experiment for Obsidian-style linking
