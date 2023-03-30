local builtin = require('telescope.builtin')

-- ========== Fuzzy Finder ==========
--
-- search files in local directory
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})

-- 
vim.keymap.set('n', '<C-p>', builtin.git_files, {})

-- search by word in files in local directory
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)

-- comandos que aprendi haciendo esto
-- shift-V para seleccionar por lineas
-- f + un caracter para moverse a la primera aparicion de este in line
