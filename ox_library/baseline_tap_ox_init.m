function baseline_tap_init(blk, varargin)
% Initialize and configure a baseline_tap block in the CASPER X Engine.
%
% baseline_tap_init(blk, varargin)
%
% blk = The baseline_tap block
% varargin = {'varname', 'value', ...} pairs
% 
% Valid varnames for this block are:
% ant_sep = The separation in time of antennae data which are to be
% cross-multiplied.
% use_ded_mult = Use dedicated cores for multiplying (otherwise, use
% slices).
% use_bram_delay = Implement the stage delay (acc_len) in a BRAM delay.

if same_state(blk, varargin{:}), return, end
check_mask_type(blk, 'baseline_tap');
munge_block(blk, varargin{:});
ant_sep = get_var('ant_sep', varargin{:});
mult_type = get_var('use_ded_mult', varargin{:});
use_bram_delay = get_var('use_bram_delay', varargin{:});
use_dsp_acc = get_var('use_dsp_acc', varargin{:});

% Replace cmult-accumulator cores with DSP version if option set
dual_pol_cmacs = find_system(blk, 'lookUnderMasks', 'all', ...
   'FollowLinks', 'on', 'Name', 'dual_pol_cmac');

if mult_type==7
    for i=1:length(dual_pol_cmacs),
        disp('Replacing cmults with dual_pol_cmac_dsp2x')
        replace_block(get_param(dual_pol_cmacs{i},'Parent'), ...
        'Name', get_param(dual_pol_cmacs{i}, 'Name'), ...
        'ox_lib/xeng/dual_pol_cmac_dsp2x', 'noprompt');
        set_param(dual_pol_cmacs{i},'LinkStatus','inactive');
    end
elseif use_dsp_acc == 1
    for i=1:length(dual_pol_cmacs),
        replace_block(get_param(dual_pol_cmacs{i},'Parent'), ...
          'Name', get_param(dual_pol_cmacs{i}, 'Name'), ...
          'ox_lib/xeng/dual_pol_cmac_dsp_acc', 'noprompt');
        set_param(dual_pol_cmacs{i},'LinkStatus','inactive');
    end
else
    for i=1:length(dual_pol_cmacs),
        replace_block(get_param(dual_pol_cmacs{i},'Parent'), ...
          'Name', get_param(dual_pol_cmacs{i}, 'Name'), ...
          'ox_lib/xeng/dual_pol_cmac', 'noprompt');
        set_param(dual_pol_cmacs{i},'LinkStatus','inactive');
    end
end

% Configure all multipliers in this block to use dedicated multipliers 
%(or not)
multipliers = find_system(blk, 'lookUnderMasks', 'all', 'FollowLinks','on','Name', 'cmult*');
for i=1:length(multipliers),
   if mult_type==2,
        replace_block(get_param(multipliers{i},'Parent'),'Name',get_param(multipliers{i},'Name'),...
            'casper_library_multipliers/cmult_4bit_br*','noprompt');
    elseif mult_type==1,
        replace_block(get_param(multipliers{i},'Parent'),'Name',get_param(multipliers{i},'Name'),...
            'casper_library_multipliers/cmult_4bit_em*','noprompt');
    elseif mult_type==3,
        replace_block(get_param(multipliers{i},'Parent'),'Name',get_param(multipliers{i},'Name'),...
            'ox_lib/xeng/combi_cmult*','noprompt');
    elseif mult_type==4,
        replace_block(get_param(multipliers{i},'Parent'),'Name',get_param(multipliers{i},'Name'),...
            'ox_lib/xeng/dsp_cmult*','noprompt');
    elseif mult_type==5,
        replace_block(get_param(multipliers{i},'Parent'),'Name',get_param(multipliers{i},'Name'),...
            'ox_lib/xeng/dualdsp_cmult*','noprompt');
    elseif mult_type==6,
        replace_block(get_param(multipliers{i},'Parent'),'Name',get_param(multipliers{i},'Name'),...
            'ox_lib/xeng/quad_cmult*','noprompt');
    else,
        replace_block(get_param(multipliers{i},'Parent'),'Name',get_param(multipliers{i},'Name'),...
            'casper_library_multipliers/cmult_4bit_sl*','noprompt');
    end
    set_param(multipliers{i},'LinkStatus','inactive');
    set_param(multipliers{i},'mult_latency','mult_latency');
    set_param(multipliers{i},'add_latency','add_latency');
end

% Configure the delay to use bram or slrs
if use_bram_delay,
    replace_block(blk,'Name','delay','casper_library_delays/delay_bram','noprompt');
    set_param([blk,'/delay'],'LinkStatus','inactive');    
    set_param([blk,'/delay'],'DelayLen','acc_len');
    set_param([blk,'/delay'],'bram_latency','bram_latency');
else,
    replace_block(blk,'Name','delay','casper_library_delays/delay_slr','noprompt');
    set_param([blk,'/delay'],'LinkStatus','inactive');    
    set_param([blk,'/delay'],'DelayLen','acc_len');    
end


fmtstr = sprintf('ant_sep=%d, mult=%d, bram=%d', ant_sep, mult_type, use_bram_delay);
set_param(blk, 'AttributesFormatString', fmtstr);
save_state(blk, varargin{:});

