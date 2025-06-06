import { useBackend } from 'tgui/backend';
import { modalOpen } from 'tgui/interfaces/common/ComplexModal';
import { Box, Button, Section, Stack } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

export const ChemMasterCustomization = (props: {
  loaded_pill_bottle: BooleanLike;
  loaded_pill_bottle_name: string;
  loaded_pill_bottle_contents_len: number;
  loaded_pill_bottle_storage_slots: number;
}) => {
  const { act } = useBackend();

  const {
    loaded_pill_bottle,
    loaded_pill_bottle_name,
    loaded_pill_bottle_contents_len,
    loaded_pill_bottle_storage_slots,
  } = props;

  if (!loaded_pill_bottle) {
    return (
      <Section title="Pill Bottle Customization">
        <Box color="label">None loaded.</Box>
      </Section>
    );
  }

  return (
    <Section title="Pill Bottle Customization">
      <Stack>
        <Stack.Item>
          <Button
            disabled={!loaded_pill_bottle}
            onClick={() => modalOpen('change_pill_bottle_style')}
          >
            Customize Bottle Color
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            disabled={!loaded_pill_bottle}
            icon="eject"
            mb="0.5rem"
            onClick={() => act('ejectp')}
          >
            {loaded_pill_bottle
              ? loaded_pill_bottle_name +
                ' (' +
                loaded_pill_bottle_contents_len +
                '/' +
                loaded_pill_bottle_storage_slots +
                ')'
              : 'None loaded'}
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
