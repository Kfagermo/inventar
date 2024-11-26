"""Add locking columns to inventory table"""

from alembic import op
import sqlalchemy as sa

def upgrade():
    op.add_column('inventory', sa.Column('locked_by', sa.String(50), nullable=True))
    op.add_column('inventory', sa.Column('locked_at', sa.DateTime, nullable=True))

def downgrade():
    op.drop_column('inventory', 'locked_by')
    op.drop_column('inventory', 'locked_at') 