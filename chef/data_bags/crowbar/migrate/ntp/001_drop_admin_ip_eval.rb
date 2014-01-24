def upgrade ta, td, a, d
  a.delete 'admin_ip_eval'
  return a, d
end

def downgrade ta, td, a, d
  a['admin_ip_eval'] = ta['admin_ip_eval']
  return a, d
end
