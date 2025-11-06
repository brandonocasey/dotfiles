// Global Vibetree configuration file
// See: https://github.com/brandonocasey/vibetree

export default {
  // Git configuration
  git: {
    mergeStrategy: "ff-only",
    autoPush: true,
  },

  // AI configuration
  ai: {
    interface: "claude",
  },

  // Tmux integration
  tmux: {
    require: true,
    rename: true,
  },
};
